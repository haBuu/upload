module Handler.Home where

import Import hiding (path)

import System.Directory
import System.FilePath
import qualified Data.Conduit.List as CL
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as B8
import Data.Time
import qualified Data.Text as T
import Data.Aeson ((.:?))

getHomeR :: Handler Html
getHomeR = do
  mAuth <- maybeAuth
  case mAuth of
    Nothing -> redirect LoginR
    Just _ -> do
      defaultLayout $ do
        addScript $ StaticR js_app_js
        $(widgetFile "homepage")

getLoginR :: Handler Html
getLoginR = do
  mAuth <- maybeAuth
  case mAuth of
    Just _ -> redirect HomeR
    Nothing -> defaultLayout $(widgetFile "login")

postLoginR :: Handler Html
postLoginR = do
  password <- runInputPost $ ireq passwordField "password"
  loginUser password
  redirect HomeR

getFileR :: Handler Value
getFileR = do
  root <- getRoot
  mpath <- lookupGetParam "path"
  let path = unpack $ fromMaybe "" mpath
  let wd = root </> path
  contents <- liftIO $ listDirectory wd
  folderNames <- filterM (isDir . combine wd) contents
  fileNames <- filterM (isFile . combine wd) contents
  render <- getUrlRender
  files <- liftIO $ forM fileNames $ mkFile render wd path
  folders <- liftIO $ forM folderNames $ mkFolder wd path
  returnJson $ object
    [ "root" .= ("files" :: Text)
    , "folders" .= folders
    , "files" .= files
    ]

postFileR :: Handler Value
postFileR = do
  root <- getRoot
  mfile <- lookupHeader "Filename"
  case mfile of
    Nothing -> invalidArgs []
    Just nameBS -> do
      let name = B8.unpack nameBS
      let fullPath = root </> name
      bs <- fmap B.concat $ rawRequestBody $$ CL.consume
      -- TODO: check that the file was written successfully
      liftIO $ B.writeFile fullPath bs
      render <- getUrlRender
      file <- liftIO $ mkFile render (takeDirectory fullPath)
        (takeDirectory $ unpack name) (takeFileName fullPath)
      sendResponseStatus status201 $ toJSON file

deleteFileR :: Handler Value
deleteFileR = do
  root <- getRoot
  file <- requireJsonBody :: Handler File
  -- TODO: check that the file was really deleted and handle exceptions gracefully
  delFile $ root </> unpack (filePath file)
  sendResponseStatus status200 ("DELETED" :: Text)

postFolderR :: Handler Value
postFolderR = do
  root <- getRoot
  (Folder path name _) <- requireJsonBody
  -- TODO: check that the folder was really created and handle exceptions gracefully
  mkDir $ root </> unpack path </> unpack name
  folder <- liftIO $ mkFolder (root </> unpack path) (unpack path) (unpack name)
  sendResponseStatus status201 $ toJSON folder

deleteFolderR :: Handler Value
deleteFolderR = do
  root <- getRoot
  folder <- requireJsonBody :: Handler Folder
  -- TODO: check that the folder was really deleted and handle exceptions gracefully
  delDir $ root </> unpack (folderPath folder)
  sendResponseStatus status200 ("DELETED" :: Text)

getRoot :: Handler String
getRoot = fmap (appStore . appSettings) getYesod

data Folder = Folder
  { folderName :: String
  , folderPath :: FilePath
  , folderTime :: Maybe String
  } deriving (Show)

data File = File
  { fileName :: String
  , filePath :: FilePath
  , icon :: Text
  , alt :: Text
  , fileTime :: String
  } deriving (Show)

instance ToJSON Folder where
  toJSON (Folder name path time) = object
    [ "name" .= name
    , "path" .= path
    , "time" .= time
    ]

instance FromJSON Folder where
  parseJSON (Object o) = Folder
    <$> o .: "name"
    <*> o .: "path"
    <*> o .:? "time"
  parseJSON _ = mzero

instance ToJSON File where
  toJSON (File name path icon alt time) = object
    [ "name" .= name
    , "path" .= path
    , "icon" .= icon
    , "alt" .= alt
    , "time" .= time
    ]

instance FromJSON File where
  parseJSON (Object o) = File
    <$> o .: "name"
    <*> o .: "path"
    <*> o .: "icon"
    <*> o .: "alt"
    <*> o .: "time"
  parseJSON _ = mzero

mkFile :: (Route App -> Text) -> String -> String -> String -> IO File
mkFile render wd path name = do
  tz <- liftIO getCurrentTimeZone
  time <- liftIO $ getModificationTime $ wd </> name
  let (icon, alt) = fileIcon $ pack $ takeExtension name
  return $ File name (path </> name) (render icon) alt $ showTime tz time

mkFolder :: String -> String -> String -> IO Folder
mkFolder wd path name = do
  tz <- liftIO getCurrentTimeZone
  time <- liftIO $ getModificationTime $ wd </> name
  return $ Folder name (path </> name) $ Just $ showTime tz time

showTime :: TimeZone -> UTCTime -> String
showTime tz time =
  formatTime defaultTimeLocale str local
  where
    local = utcToLocalTime tz time
    str = "%e.%m.%Y %R"

delDir :: FilePath -> Handler ()
delDir = liftIO . removeDirectoryRecursive
mkDir ::  FilePath -> Handler ()
mkDir = liftIO . createDirectoryIfMissing True
isDir ::  FilePath -> Handler Bool
isDir = liftIO . doesDirectoryExist
isFile ::  FilePath -> Handler Bool
isFile = liftIO . doesFileExist
delFile ::  FilePath -> Handler ()
delFile = liftIO . removeFile

fileIcon :: Text -> (Route App, Text)
fileIcon ".aac" = (StaticR img_aac_png, "AAC")
fileIcon ".aiff" = (StaticR img_aiff_png, "AIFF")
fileIcon ".ai" = (StaticR img_ai_png, "AI")
fileIcon ".avi" = (StaticR img_avi_png, "AVI")
fileIcon ".bmp" = (StaticR img_bmp_png, "BMP")
fileIcon ".c" = (StaticR img_c_png, "C")
fileIcon ".cpp" = (StaticR img_cpp_png, "CPP")
fileIcon ".css" = (StaticR img_css_png, "CSS")
fileIcon ".dat" = (StaticR img_dat_png, "DAT")
fileIcon ".dmg" = (StaticR img_dmg_png, "DMG")
fileIcon ".doc" = (StaticR img_doc_png, "DOC")
fileIcon ".docx" = (StaticR img_doc_png, "DOCX")
fileIcon ".dotx" = (StaticR img_dotx_png, "DOTX")
fileIcon ".dwg" = (StaticR img_dwg_png, "DWG")
fileIcon ".dxf" = (StaticR img_dxf_png, "DXF")
fileIcon ".eps" = (StaticR img_eps_png, "EPS")
fileIcon ".exe" = (StaticR img_exe_png, "EXE")
fileIcon ".flv" = (StaticR img_flv_png, "FLV")
fileIcon ".gif" = (StaticR img_gif_png, "GIF")
fileIcon ".h" = (StaticR img_h_png, "H")
fileIcon ".hpp" = (StaticR img_hpp_png, "HPP")
fileIcon ".html" = (StaticR img_html_png, "HTML")
fileIcon ".ics" = (StaticR img_ics_png, "ICS")
fileIcon ".iso" = (StaticR img_iso_png, "ISO")
fileIcon ".java" = (StaticR img_java_png, "JAVA")
fileIcon ".jpg" = (StaticR img_jpg_png, "JPG")
fileIcon ".jpeg" = (StaticR img_jpg_png, "JPEG")
fileIcon ".js" = (StaticR img_js_png, "JS")
fileIcon ".key" = (StaticR img_key_png, "KEY")
fileIcon ".less" = (StaticR img_less_png, "LESS")
fileIcon ".mid" = (StaticR img_mid_png, "MID")
fileIcon ".midi" = (StaticR img_mid_png, "MIDI")
fileIcon ".mp3" = (StaticR img_mp3_png, "MP3")
fileIcon ".mp4" = (StaticR img_mp4_png, "MP4")
fileIcon ".mpg" = (StaticR img_mpg_png, "MPG")
fileIcon ".mpeg" = (StaticR img_mpg_png, "MPG")
fileIcon ".odf" = (StaticR img_odf_png, "ODF")
fileIcon ".ods" = (StaticR img_ods_png, "ODS")
fileIcon ".odt" = (StaticR img_odt_png, "ODT")
fileIcon ".otp" = (StaticR img_otp_png, "OTP")
fileIcon ".ots" = (StaticR img_ots_png, "OTS")
fileIcon ".ott" = (StaticR img_ott_png, "OTT")
fileIcon ".pdf" = (StaticR img_pdf_png, "PDF")
fileIcon ".php" = (StaticR img_php_png, "PHP")
fileIcon ".png" = (StaticR img_png_png, "PNG")
fileIcon ".ppt" = (StaticR img_ppt_png, "PPT")
fileIcon ".pptx" = (StaticR img_ppt_png, "PPTX")
fileIcon ".psd" = (StaticR img_psd_png, "PSD")
fileIcon ".py" = (StaticR img_py_png, "PY")
fileIcon ".qt" = (StaticR img_qt_png, "QT")
fileIcon ".rar" = (StaticR img_rar_png, "RAR")
fileIcon ".rb" = (StaticR img_rb_png, "RB")
fileIcon ".rtf" = (StaticR img_rtf_png, "RTF")
fileIcon ".sass" = (StaticR img_sass_png, "SASS")
fileIcon ".scss" = (StaticR img_scss_png, "SCSS")
fileIcon ".sql" = (StaticR img_sql_png, "SQL")
fileIcon ".tga" = (StaticR img_tga_png, "TGA")
fileIcon ".tgz" = (StaticR img_tgz_png, "TGZ")
fileIcon ".tiff" = (StaticR img_tiff_png, "TIFF")
fileIcon ".txt" = (StaticR img_txt_png, "TXT")
fileIcon ".log" = (StaticR img_txt_png, "TXT")
fileIcon ".wav" = (StaticR img_wav_png, "WAV")
fileIcon ".xls" = (StaticR img_xls_png, "XLS")
fileIcon ".xlsx" = (StaticR img_xlsx_png, "XLSX")
fileIcon ".xml" = (StaticR img_xml_png, "XML")
fileIcon ".yml" = (StaticR img_yml_png, "YML")
fileIcon ".zip" = (StaticR img_zip_png, "ZIP")
fileIcon "" = (StaticR img_blank_png, "FILE")
fileIcon ext = (StaticR img_blank_png, T.toUpper $ T.drop 1 ext)

listDirectory :: FilePath -> IO [FilePath]
listDirectory path =
  filter f <$> getDirectoryContents path
  where f filename = filename /= "." && filename /= ".."
