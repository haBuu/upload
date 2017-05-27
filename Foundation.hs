module Foundation where

import Import.NoFoundation
import Text.Hamlet                 (hamletFile)
import Text.Jasmine                (minifym)
import Yesod.Core.Types            (Logger)
import Yesod.Default.Util          (addStaticContentExternal)
import qualified Yesod.Core.Unsafe as Unsafe
import qualified Data.CaseInsensitive as CI
import qualified Data.Text.Encoding as TE

-- | The foundation datatype for your application. This can be a good place to
-- keep settings and values requiring initialization before your application
-- starts running, such as database connections. Every handler will have
-- access to the data present here.
data App = App
    { appSettings    :: AppSettings
    , appStatic      :: Static -- ^ Settings for static file serving.
    , appFiles       :: Static
    , appHttpManager :: Manager
    , appLogger      :: Logger
    }

-- This is where we define all of the routes in our application. For a full
-- explanation of the syntax, please see:
-- http://www.yesodweb.com/book/routing-and-handlers
--
-- Note that this is really half the story; in Application.hs, mkYesodDispatch
-- generates the rest of the code. Please see the following documentation
-- for an explanation for this split:
-- http://www.yesodweb.com/book/scaffolding-and-the-site-template#scaffolding-and-the-site-template_foundation_and_application_modules
--
-- This function also generates the following type synonyms:
-- type Handler = HandlerT App IO
-- type Widget = WidgetT App IO ()
mkYesodData "App" $(parseRoutesFile "config/routes")

-- | A convenient synonym for creating forms.
type Form x = Html -> MForm (HandlerT App IO) (FormResult x, Widget)

-- Please see the documentation for the Yesod typeclass. There are a number
-- of settings which can be configured by overriding methods here.
instance Yesod App where
    -- Controls the base of generated URLs. For more information on modifying,
    -- see: https://github.com/yesodweb/yesod/wiki/Overriding-approot
    approot = ApprootRequest $ \app req ->
      case appRoot $ appSettings app of
        Nothing -> getApprootText guessApproot app req
        Just root -> root

    -- Store session data on the client in encrypted cookies,
    -- default session idle timeout is 120 minutes
    makeSessionBackend _ = Just <$> defaultClientSessionBackend
      120    -- timeout in minutes
      "config/client_session_key.aes"

    -- Yesod Middleware allows you to run code before and after each handler function.
    -- The defaultYesodMiddleware adds the response header "Vary: Accept, Accept-Language" and performs authorization checks.
    -- Some users may also want to add the defaultCsrfMiddleware, which:
    --   a) Sets a cookie with a CSRF token in it.
    --   b) Validates that incoming write requests include that token in either a header or POST parameter.
    -- To add it, chain it together with the defaultMiddleware: yesodMiddleware = defaultYesodMiddleware . defaultCsrfMiddleware
    -- For details, see the CSRF documentation in the Yesod.Core.Handler module of the yesod-core package.
    yesodMiddleware = defaultYesodMiddleware

    defaultLayout widget = do
      master <- getYesod

      pc <- widgetToPageContent $ do
        addStylesheetRemote "//maxcdn.bootstrapcdn.com/bootstrap/4.0.0-alpha.5/css/bootstrap.min.css"
        addScriptRemote "//cdn.rawgit.com/zenorocha/clipboard.js/v1.5.16/dist/clipboard.min.js"
        $(widgetFile "default-layout")
        $(widgetFile "style")
      withUrlRenderer $(hamletFile "templates/default-layout-wrapper.hamlet")

    -- Routes not requiring authentication.
    isAuthorized FaviconR _ = return Authorized
    isAuthorized RobotsR _ = return Authorized
    isAuthorized (StaticR _) _ = return Authorized
    isAuthorized (FilesR path) _ = filePermission path
    isAuthorized HomeR _ = return Authorized
    isAuthorized LoginR _ = return Authorized

    -- Allow downloading folders wihout authentication
    -- Same as FilesR but for zipped folders
    isAuthorized FolderR False = return Authorized

    -- Protect the API
    isAuthorized _ _ = isAuth

    -- This function creates static content files in the static folder
    -- and names them based on a hash of their content. This allows
    -- expiration dates to be set far in the future without worry of
    -- users receiving stale content.
    addStaticContent ext mime content = do
      master <- getYesod
      let staticDir = appStaticDir $ appSettings master
      addStaticContentExternal
        minifym
        genFileName
        staticDir
        (StaticR . flip StaticRoute [])
        ext
        mime
        content
      where
        -- Generate a unique filename based on the content itself
        genFileName lbs = "autogen-" ++ base64md5 lbs

    -- What messages should be logged. The following includes all messages when
    -- in development, and warnings and errors in production.
    shouldLog app _source level =
      appShouldLogAll (appSettings app)
        || level == LevelWarn
        || level == LevelError

    makeLogger = return . appLogger

    maximumContentLength app (Just FileR) = Just $ appSizeLimit (appSettings app) * 1024 * 1024
    maximumContentLength _ _ = Just $ 2 * 1024 * 1024 -- 2 megabytes

-- This instance is required to use forms. You can modify renderMessage to
-- achieve customized and internationalized form validation messages.
instance RenderMessage App FormMessage where
  renderMessage _ _ = defaultFormMessage

-- Useful when writing code that is re-usable outside of the Handler context.
-- An example is background jobs that send email.
-- This can also be useful for writing code that works across multiple Yesod applications.
instance HasHttpManager App where
  getHttpManager = appHttpManager

unsafeHandler :: App -> Handler a -> IO a
unsafeHandler = Unsafe.fakeHandlerGetLogger appLogger

-- Authentication helpers
maybeAuth :: Handler (Maybe Text)
maybeAuth = do
  noAuth <- fmap (appNoAuth . appSettings) getYesod
  if noAuth then return $ Just "_AUTH" else lookupSession "_AUTH"

loginUser :: Text -> Handler ()
loginUser pw = do
  password <- fmap (appPassword . appSettings) getYesod
  when (pw == password) $ setSession "_AUTH" pw

filePermission :: Route Static -> Handler AuthResult
filePermission route = do
  let (parts, _) = renderRoute route
  public <- liftIO $ isPublic $ intercalate "/" parts
  if public then return Authorized else isAuth

getPublicFiles :: IO [Text]
getPublicFiles = fmap lines $ readFile "public.txt"

isPublic :: Text -> IO Bool
isPublic path = do
  files <- getPublicFiles
  return $ elem path files

setPublic :: Text -> IO ()
setPublic path = do
  files <- getPublicFiles
  if elem path files
    then return ()
    else writeFile "public.txt" $ unlines $ path:files

setPrivate :: Text -> IO ()
setPrivate path = do
  files <- getPublicFiles
  print files
  print path
  if elem path files
    then writeFile "public.txt" $ unlines $ filter ((/=) path) files
    else return ()

isAuth :: Handler AuthResult
isAuth = do
  mAuth <- maybeAuth
  return $ case mAuth of
    Nothing -> Unauthorized ""
    Just _ -> Authorized
