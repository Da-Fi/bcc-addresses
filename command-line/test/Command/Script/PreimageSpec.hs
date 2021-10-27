{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE QuasiQuotes #-}

module Command.Script.PreimageSpec
    ( spec
    ) where

import Prelude

import Bcc.Address.Script
    ( ErrValidateScript (..), prettyErrValidateScript )
import Data.String.Interpolate
    ( iii )
import Test.Hspec
    ( Spec, SpecWith, it, shouldBe, shouldContain )
import Test.Utils
    ( cli, describeCmd )

spec :: Spec
spec = do
    describeCmd [ "script", "preimage" ] $ do
        specScriptPreimageProper
            "008201818200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef10d"
            [iii|all [ #{verKeyH1} ]|]

        specScriptPreimageProper
            "008201818200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef10d"
            ("all    [ " <>verKeyH1<>"  ] ")

        specScriptPreimageProper
            "008201838200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef10\
            \d8200581c2445facc08d975d9d965d360dbe0fa63688ccc8f70fd7e1f01135380820058\
            \1cf51d0d9716bee309bb109f954ac488e1b3c06fcc28f56fe906a7ae74"
            [iii|all [ #{verKeyH1}, #{verKeyH2}, #{verKeyH3} ]|]

        specScriptPreimageProper
            "008202818200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef10d"
            [iii|any [ #{verKeyH1} ]|]

        specScriptPreimageProper
            "008202838200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef10\
            \d8200581c2445facc08d975d9d965d360dbe0fa63688ccc8f70fd7e1f01135380820058\
            \1cf51d0d9716bee309bb109f954ac488e1b3c06fcc28f56fe906a7ae74"
            [iii|any [ #{verKeyH1}, #{verKeyH2}, #{verKeyH3} ]|]

        specScriptPreimageProper
            "00830301838200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef\
            \10d8200581c2445facc08d975d9d965d360dbe0fa63688ccc8f70fd7e1f011353808200\
            \581cf51d0d9716bee309bb109f954ac488e1b3c06fcc28f56fe906a7ae74"
            [iii|at_least 1 [ #{verKeyH1}, #{verKeyH2}, #{verKeyH3} ]|]

        specScriptPreimageProper
            "00830301828200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef\
            \10d8201828200581c2445facc08d975d9d965d360dbe0fa63688ccc8f70fd7e1f011353\
            \808200581cf51d0d9716bee309bb109f954ac488e1b3c06fcc28f56fe906a7ae74"
            [iii|at_least 1 [ #{verKeyH1}, all [ #{verKeyH2}, #{verKeyH3} ] ]|]

        specScriptPreimageProper
            "008200581c4e73a20ff3c0ae90fbc95f278d42721b1f763e055024a0e6be6aeb71"
            [iii|#{verKeyH4}|]

        specScriptInvalid Malformed
            [iii|wrong [ #{verKeyH1} ]|]

        specScriptInvalid Malformed
            [iii|any [ #{verKeyH1}, ]|]

        specScriptPreimageProper
            "00830304838200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef\
            \10d8200581c2445facc08d975d9d965d360dbe0fa63688ccc8f70fd7e1f011353808200\
            \581cf51d0d9716bee309bb109f954ac488e1b3c06fcc28f56fe906a7ae74"
            [iii|at_least 4 [ #{verKeyH1}, #{verKeyH2}, #{verKeyH3} ]|]

        specScriptPreimageProper
            "00830301828200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef\
            \10d830302818200581c2445facc08d975d9d965d360dbe0fa63688ccc8f70fd7e1f01135380"
            [iii|at_least 1 [ #{verKeyH1}, at_least 2 [ #{verKeyH2} ] ]|]

        specScriptPreimageProper
            "00820180"
            [iii|all []|]

        specScriptPreimageProper
            "008202828200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef10d820180"
            [iii|any [ #{verKeyH1}, all [] ]|]

        specScriptPreimageProper
            "00830300828200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef10\
            \d8200581c2445facc08d975d9d965d360dbe0fa63688ccc8f70fd7e1f01135380"
            [iii|at_least 0 [ #{verKeyH1}, #{verKeyH2} ]|]

        specScriptPreimageProper
            "00830301848200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef10\
            \d8200581c2445facc08d975d9d965d360dbe0fa63688ccc8f70fd7e1f0113538082040a82051819"
            [iii|at_least 1 [ #{verKeyH1}, #{verKeyH2}, active_from 10, active_until 25 ]|]

        specScriptPreimageProper
            "008202838200581c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef10\
            \d8200581c2445facc08d975d9d965d360dbe0fa63688ccc8f70fd7e1f01135380820058\
            \1c1196fe3062e96b78dd959058f5adad44dd663519200f2495d17ef10d"
            [iii|any [ #{verKeyH1}, #{verKeyH2}, #{verKeyH1}]|]

        specScriptInvalid Malformed
            [iii|script_vkh18srsxr3khll7vl3w9mqfu55n6wzxxlxjq8egs9|]

        specScriptInvalid Malformed
            [iii|any [ #{verKeyH1}, #{verKeyH2}, active_from a]|]

specScriptPreimageProper :: String -> String -> SpecWith ()
specScriptPreimageProper expected script = it (script <> " => " <> expected) $ do
    out <- cli ["script", "preimage", script] ""
    out `shouldBe` expected

specScriptInvalid :: ErrValidateScript -> String -> SpecWith ()
specScriptInvalid errMsg script = it (script <> " => " <> show errMsg) $ do
    (out, err) <- cli ["script", "preimage", script] ""
    out `shouldBe` ("" :: String)
    err `shouldContain` (prettyErrValidateScript errMsg)

verKeyH1 :: String
verKeyH1 = "addr_shared_vkh1zxt0uvrza94h3hv4jpv0ttddgnwkvdgeyq8jf9w30mcs6y8w3nq"

verKeyH2 :: String
verKeyH2 = "addr_shared_vkh1y3zl4nqgm96ankt96dsdhc86vd5geny0wr7hu8cpzdfcqskq2cp"

verKeyH3 :: String
verKeyH3 = "addr_shared_vkh175wsm9ckhm3snwcsn72543yguxeuqm7v9r6kl6gx57h8gdydcd9"

verKeyH4 :: String
verKeyH4 = "addr_shared_vkh1fee6yrlnczhfp77ftunc6snjrv0hv0s92qj2pe47dt4hz8ajp6a"
