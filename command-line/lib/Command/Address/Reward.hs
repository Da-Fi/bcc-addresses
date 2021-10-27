{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

{-# OPTIONS_HADDOCK hide #-}

module Command.Address.Reward
    ( Cmd
    , mod
    , run
    ) where

import Prelude hiding
    ( mod )

import Bcc.Address
    ( NetworkTag (..), unAddress )
import Bcc.Address.Derivation
    ( xpubFromBytes )
import Bcc.Address.Script
    ( scriptHashFromBytes )
import Bcc.Address.Style.Sophie
    ( Credential (..), sophieTestnet, unsafeFromRight )
import Codec.Binary.Encoding
    ( AbstractEncoding (..) )
import Options.Applicative
    ( CommandFields, Mod, command, footerDoc, header, helper, info, progDesc )
import Options.Applicative.Discrimination
    ( fromNetworkTag, networkTagOpt )
import Options.Applicative.Help.Pretty
    ( bold, indent, string, vsep )
import Options.Applicative.Style
    ( Style (..) )
import System.IO
    ( stdin, stdout )
import System.IO.Extra
    ( hGetBech32, hPutBytes, progName )

import qualified Bcc.Address.Style.Sophie as Sophie
import qualified Bcc.Codec.Bech32.Prefixes as CIP5

newtype Cmd = Cmd
    {  networkTag :: NetworkTag
    } deriving (Show)

mod :: (Cmd -> parent) -> Mod CommandFields parent
mod liftCmd = command "stake" $
    info (helper <*> fmap liftCmd parser) $ mempty
        <> progDesc "Create a stake address"
        <> header "Create a stake address \
            \that references a delegation key (1-1)."
        <> footerDoc (Just $ vsep
            [ string "The public key is read from stdin."
            , string ""
            , string "Example:"
            , indent 2 $ bold $ string $ "$ "<>progName<>" recovery-phrase generate --size 15 \\"
            , indent 4 $ bold $ string $ "| "<>progName<>" key from-recovery-phrase Sophie > root.prv"
            , indent 2 $ string ""
            , indent 2 $ bold $ string "$ cat root.prv \\"
            , indent 4 $ bold $ string $ "| "<>progName<>" key child 1852H/1815H/0H/2/0 > stake.prv"
            , indent 2 $ string ""
            , indent 2 $ bold $ string "$ cat stake.prv \\"
            , indent 4 $ bold $ string $ "| "<>progName<>" key public --with-chain-code \\"
            , indent 4 $ bold $ string $ "| "<>progName<>" address stake --network-tag testnet"
            , indent 2 $ string "stake_test1uzp7swuxjx7wmpkkvat8kpgrmjl8ze0dj9lytn25qv2tm4g6n5c35"
            ])
  where
    parser = Cmd
        <$> networkTagOpt Sophie

run :: Cmd -> IO ()
run Cmd{networkTag} = do
    discriminant <- fromNetworkTag networkTag
    (hrp, bytes) <- hGetBech32 stdin allowedPrefixes
    addr <- stakeAddressFromBytes discriminant bytes hrp
    hPutBytes stdout (unAddress addr) (EBech32 stakeHrp)
  where
    stakeHrp
        | networkTag == sophieTestnet = CIP5.stake_test
        | otherwise = CIP5.stake

    -- TODO: Also allow `XXX_vk` prefixes. We don't need the chain code to
    -- construct a payment credential. This will however need some additional
    -- abstraction over `xpubFromBytes` but I've done enough yake-shaving at
    -- this stage, so leaving this as an item for later.
    allowedPrefixes =
        [ CIP5.stake_xvk
        , CIP5.script
        ]

    stakeAddressFromBytes discriminant bytes hrp
        | hrp == CIP5.script = do
            case scriptHashFromBytes bytes of
                Nothing ->
                    fail "Couldn't convert bytes into script hash."
                Just h  -> do
                    let credential = DelegationFromScript h
                    pure $ unsafeFromRight $ Sophie.stakeAddress discriminant credential

        | otherwise = do
            case xpubFromBytes bytes of
                Nothing  ->
                    fail "Couldn't convert bytes into extended public key."
                Just key -> do
                    let credential = DelegationFromKey $ Sophie.liftXPub key
                    pure $ unsafeFromRight $ Sophie.stakeAddress discriminant credential
