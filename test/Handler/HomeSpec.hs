module Handler.HomeSpec (spec) where

import TestImport

import System.Directory

assertDirExists :: Bool -> String -> YesodExample App ()
assertDirExists cond dir = do
  exists <- liftIO $ doesDirectoryExist $ root </> dir
  assertEq "Does directory exist" cond exists

assertFileExists :: Bool -> String -> YesodExample App ()
assertFileExists cond file = do
  exists <- liftIO $ doesFileExist $ root </> file
  assertEq "Does file exist" cond exists

spec :: Spec
spec = withApp $ do

  describe "Homepage" $ do
    it "Check that the front page handler works" $ do

      get HomeR
      statusIs 200

  describe "Add folder and delete folder" $ do
    it "Check that adding and deleting folders work" $ do

      assertDirExists False "test"

      postBody FolderR $ encode $ object
        [ "path" .= ("" :: String)
        , "name" .= ("test" :: String)
        ]

      statusIs 201
      assertDirExists True "test"

      request $ do
        setMethod "DELETE"
        setUrl FolderR
        setRequestBody $ encode $ object
          [ "path" .= ("test" :: String)
          , "name" .= ("test" :: String)
          , "time" .= ("" :: String)
          ]

      statusIs 200
      bodyEquals "DELETED"
      assertDirExists False "test"

  describe "Add and delete file" $ do
    it "Check that adding and deleting files work" $ do

      assertFileExists False "test"

      request $ do
        setMethod "POST"
        setUrl FileR
        addRequestHeader ("Filename", "test")
        setRequestBody "testing"

      statusIs 201
      assertFileExists True "test"

      request $ do
        setMethod "DELETE"
        setUrl FileR
        setRequestBody $ encode $ object
          [ "path" .= ("test" :: String)
          , "name" .= ("" :: String)
          , "icon" .= ("" :: String)
          , "alt" .= ("" :: String)
          , "time" .= ("" :: String)
          ]

      statusIs 200
      assertFileExists False "test"

      -- Now without header
      request $ do
        setMethod "POST"
        setUrl FileR
        setRequestBody "testing"

      statusIs 400
      assertFileExists False "test"
