import Syntax
import Parser
import Eval

import Control.Monad.State
import System.IO (hFlush, stdout)
import Debug.Trace
import System.Exit


execAll :: [String] -> Environment -> Environment
execAll lines env = foldl exec env lines  where
    exec env line = case readExpr line of
        (Left err) -> env
        (Right ex) -> do
            case ex of
                Define v e -> snd $ (evalDefine v e) `runState` env

showGlobal :: (Variable, Expression) -> IO ()
showGlobal (n, e) = putStrLn ("   " ++ show n ++ " = " ++ show e)


execute :: String -> Environment -> IO Environment
execute line env =
    case readLine line of
        Left (SyntaxError e) -> do
            putStrLn $ show e
            return env
        Right c -> do
            case c of 
                Define v e -> do 
                    let (res, env') = (evalDefine v e) `runState` env
                    case res of
                        Left err -> putStrLn $ show err
                        Right f -> putStrLn ("- added " ++ show f ++ " to environment as " ++ show v) 
                    return env'
                Execute e -> do
                    let (res, env') = (evalE e) `runState` env
                    case res of
                        Left err -> putStrLn $ show err
                        Right f -> putStrLn ("----- result: " ++ show f)
                    return env
                Import f -> do
                    contents <- readFile f
                    let exprs = lines contents
                    putStrLn ("- imported all from " ++ show f)
                    return $ execAll exprs env
                Review r -> do
                    case r of
                       "all" -> do
                           putStrLn ("ENVIRONMENT:")
                           mapM_ showGlobal env
                       -- otherwise lookup value
                    return env
                    


-- MAIN with Read-Evaluate-Print Loop --
main :: IO ()
main = do
    repl [] where
        repl env = do
            putStr "LCI> "
            hFlush stdout
            line <- getLine
            case line of
                ":quit" -> exitSuccess
                otherwise -> do
                    env' <- execute line env
                    repl env'
