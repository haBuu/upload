module Handler.HomeSpec (spec) where

import TestImport

import System.Directory

import Settings

assertDirExists :: Bool -> String -> YesodExample App ()
assertDirExists cond dir = do
  root <- getRoot
  exists <- liftIO $ doesDirectoryExist $ root </> dir
  assertEq "Does directory exist" cond exists

assertFileExists :: Bool -> String -> YesodExample App ()
assertFileExists cond file = do
  root <- getRoot
  exists <- liftIO $ doesFileExist $ root </> file
  assertEq "Does file exist" cond exists

getRoot :: YesodExample App String
getRoot = fmap (appStore . appSettings) getTestYesod

spec :: Spec
spec = withApp $ do

  describe "Home" $ do
    it "Check that the front page handler works" $ do

      get HomeR
      statusIs 200

  describe "File" $ do
    it "Check that the file handler works" $ do

      get FileR
      statusIs 200

  describe "Add folder and delete folder" $ do
    it "Check that adding and deleting folders work" $ do

      get FileR
      statusIs 200
      bodyNotContains "test"

      assertDirExists False "test"

      postBody FolderR $ encode $ object
        [ "path" .= ("" :: String)
        , "name" .= ("test" :: String)
        ]

      statusIs 201
      assertDirExists True "test"

      get FileR
      statusIs 200
      bodyContains "test"

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

      get FileR
      statusIs 200
      bodyNotContains "test"

  describe "Add and delete file" $ do
    it "Check that adding and deleting files work" $ do

      get FileR
      statusIs 200
      bodyNotContains "test"

      assertFileExists False "test"

      request $ do
        setMethod "POST"
        setUrl FileR
        addRequestHeader ("Filename", "test")
        setRequestBody "testing"

      statusIs 201
      assertFileExists True "test"

      get FileR
      statusIs 200
      bodyContains "test"

      request $ do
        setMethod "DELETE"
        setUrl FileR
        setRequestBody $ encode $ object
          [ "path" .= ("test" :: String)
          , "name" .= ("" :: String)
          , "icon" .= ("" :: String)
          , "alt" .= ("" :: String)
          , "time" .= ("" :: String)
          , "public" .= (True :: Bool)
          ]

      statusIs 200
      assertFileExists False "test"

      get FileR
      statusIs 200
      bodyNotContains "test"

      -- Now without header
      request $ do
        setMethod "POST"
        setUrl FileR
        setRequestBody "testing"

      statusIs 400
      assertFileExists False "test"

      get FileR
      statusIs 200
      bodyNotContains "test"

  describe "Search" $ do
    it "Check that searching works" $ do

      assertFileExists False "test"

      request $ do
        setMethod "GET"
        setUrl FindR
        addGetParam "find" ""

      statusIs 200
      bodyNotContains "test"

      root <- getRoot
      liftIO $ writeFile (root </> "test") ("testing" :: Text)
      assertFileExists True "test"

      request $ do
        setMethod "GET"
        setUrl FindR
        addGetParam "find" "test"

      statusIs 200
      bodyContains "test"

      liftIO $ removeFile (root </> "test")
