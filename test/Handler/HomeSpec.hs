module Handler.HomeSpec (spec) where

import TestImport

import System.Directory

assertExists :: Bool -> String -> YesodExample App ()
assertExists cond dir = do
  exists <- liftIO $ doesDirectoryExist $ root </> dir
  assertEq "Does directory exist" cond exists

spec :: Spec
spec = withApp $ do

  describe "Homepage" $ do
    it "Check that the front page handler works" $ do

      get HomeR
      statusIs 200

  describe "Add folder and remove folder" $ do
    it "Check that adding and deleting folders work" $ do

      assertExists False "test"

      postBody FolderR $ encode $ object
        [ "path" .= ("" :: String)
        , "name" .= ("test" :: String)]

      statusIs 201
      assertExists True "test"

      request $ do
        setMethod "DELETE"
        setUrl FolderR
        setRequestBody $ encode $ object
          [ "path" .= ("test" :: String)
          , "name" .= ("test" :: String)
          , "time" .= ("" :: String)]

      statusIs 200
      bodyEquals "DELETED"
      assertExists False "test"
