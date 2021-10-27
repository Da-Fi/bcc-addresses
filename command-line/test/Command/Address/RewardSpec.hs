{-# LANGUAGE FlexibleContexts #-}

module Command.Address.RewardSpec
    ( spec
    ) where

import Prelude

import Test.Hspec
    ( Spec, SpecWith, it, shouldBe, shouldContain )
import Test.Utils
    ( cli, describeCmd )

spec :: Spec
spec = describeCmd [ "address", "stake" ] $ do
    specSophie defaultPhrase "1852H/1815H/0H/2/0" 0
        "stake_test1ura3dk68y6echdmfmnvm8mej8u5truwv8ufmv830w5a45tcsfhtt2"

    specSophie defaultPhrase "1852H/1815H/0H/2/0" 3
        "stake1u0a3dk68y6echdmfmnvm8mej8u5truwv8ufmv830w5a45tchw5z0e"

    specMalformedNetwork "💩"

    specInvalidNetwork "42"

specSophie :: [String] -> String -> Int -> String -> SpecWith ()
specSophie phrase path networkTag want = it ("golden sophie (payment) " <> path) $ do
    out <- cli [ "key", "from-recovery-phrase", "sophie" ] (unwords phrase)
       >>= cli [ "key", "child", path ]
       >>= cli [ "key", "public", "--with-chain-code" ]
       >>= cli [ "address", "stake", "--network-tag", show networkTag ]
    out `shouldBe` want

specMalformedNetwork :: String -> SpecWith ()
specMalformedNetwork networkTag = it ("malformed network " <> networkTag) $ do
    (out, err) <- cli [ "key", "from-recovery-phrase", "sophie" ] (unwords defaultPhrase)
        >>= cli [ "key", "public", "--with-chain-code" ]
        >>= cli [ "address", "stake", "--network-tag", networkTag ]
    out `shouldBe` ""
    err `shouldContain` "Invalid network tag"
    err `shouldContain` "Usage"

specInvalidNetwork :: String -> SpecWith ()
specInvalidNetwork networkTag = it ("invalid network " <> networkTag) $ do
    (out, err) <- cli [ "key", "from-recovery-phrase", "sophie" ] (unwords defaultPhrase)
        >>= cli [ "key", "public", "--with-chain-code" ]
        >>= cli [ "address", "stake", "--network-tag", networkTag ]
    out `shouldBe` ""
    err `shouldContain` "Invalid network tag"

defaultPhrase :: [String]
defaultPhrase =
    [ "pole", "pulse", "wolf", "blame", "chronic"
    , "ship", "vivid", "tree", "small", "onion"
    , "host", "accident", "burden", "lazy", "swarm"
    ]
