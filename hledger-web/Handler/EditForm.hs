-- -- | Handle a post from the journal edit form.
-- handleEdit :: Handler Html
-- handleEdit = do
--   VD{..} <- getViewData
--   -- get form input values, or validation errors.
--   -- getRequest >>= liftIO (reqRequestBody req) >>= mtrace
--   mtext <- lookupPostParam "text"
--   mtrace "--------------------------"
--   mtrace (journalFilePaths j)
--   mjournalpath <- lookupPostParam "journal"
--   let etext = maybe (Left "No value provided") (Right . unpack) mtext
--       ejournalpath = maybe
--                        (Right $ journalFilePath j)
--                        (\f -> let f' = unpack f in
--                               if f' `elem` dbg0 "paths2" (journalFilePaths j)
--                               then Right f'
--                               else Left ("unrecognised journal file path"::String))
--                        mjournalpath
--       estrs = [etext, ejournalpath]
--       errs = lefts estrs
--       [text,journalpath] = rights estrs
--   -- display errors or perform edit
--   if not $ null errs
--    then do
--     setMessage $ toHtml (intercalate "; " errs :: String)
--     redirect JournalR

-- -- | Handle a post from the journal edit form.
-- handleEdit :: Handler Html
-- handleEdit = do
--   VD{..} <- getViewData
--   -- get form input values, or validation errors.
--   -- getRequest >>= liftIO (reqRequestBody req) >>= mtrace
--   mtext <- lookupPostParam "text"
--   mjournalpath <- lookupPostParam "journal"
--   let etext = maybe (Left "No value provided") (Right . unpack) mtext
--       ejournalpath = maybe
--                        (Right $ journalFilePath j)
--                        (\f -> let f' = unpack f in
--                               if f' `elem` journalFilePaths j
--                               then Right f'
--                               else Left ("unrecognised journal file path"::String))
--                        mjournalpath
--       estrs = [etext, ejournalpath]
--       errs = lefts estrs
--       [text,journalpath] = rights estrs
--   -- display errors or perform edit
--   if not $ null errs
--    then do
--     setMessage $ toHtml (intercalate "; " errs :: String)
--     redirect JournalR

--    else do
--     -- try to avoid unnecessary backups or saving invalid data
--     filechanged' <- liftIO $ journalSpecifiedFileIsNewer j journalpath
--     told <- liftIO $ readFileStrictly journalpath
--     let tnew = filter (/= '\r') text
--         changed = tnew /= told || filechanged'
--     if not changed
--      then do
--        setMessage "No change"
--        redirect JournalR
--      else do
--       jE <- liftIO $ readJournal def (Just journalpath) tnew
--       either
--        (\e -> do
--           setMessage $ toHtml e
--           redirect JournalR)
--        (const $ do
--           liftIO $ writeFileWithBackup journalpath tnew
--           setMessage $ toHtml (printf "Saved journal %s\n" (show journalpath) :: String)
--           redirect JournalR)
--        jE


