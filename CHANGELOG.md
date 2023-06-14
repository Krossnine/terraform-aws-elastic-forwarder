# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

### [0.0.2](https://github.com/Krossnine/terraform-aws-elastic-forwarder/compare/v0.0.1...v0.0.2) (2023-06-14)


### 📚 Documentation

* **readme:** update bump and build workflow file badge ([eff2602](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/eff26023895a60a7ee1a1481dfff26b191257944))


### 🐛 Bug Fixes

* **lambda:** debug postbuild zip path ([3ee5053](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/3ee5053a7e209c06a9ae605bb6ebdc6eb472ac6a))
* **module:** add fetch with tags to bump module workflow and step ([#20](https://github.com/Krossnine/terraform-aws-elastic-forwarder/issues/20)) ([05405ba](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/05405ba39f31d5289744001e81424e64ec66c27f))
* **module:** debug bump step by add fetch prune unshallow ([1f520ef](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/1f520efa4e765ab739175faaf3a178f566e001f1))
* **module:** debug bump step by pulling tags ([a431e94](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/a431e944a8a0b768f7de1157e07edf96c240df03))
* **module:** debug bump step by removing --unshallow flag on fetch prune ([ddeaf45](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/ddeaf456fb9895eb53d1835c2ea4d21be380a401))
* **module:** try debug bump and build tag creation ([b80e918](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/b80e9180d9f545df41963fd15628efbe2ede57d2))
* **module:** try debug bump and build tag creation ([f5a7412](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/f5a741255ac70f99b8bb7b3200e6935231eeddbc))
* **test:** debug and enable integration test workflow ([aa64a2e](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/aa64a2e75b0331ecb3da30671bf2b6e059786080))


### 🏗  Chore

* **bump:** add fetch-depth param to checkout for semver ([5547b8f](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/5547b8ff62df911a6be5b4745a10fd07efc0a0fa))
* **bump:** change file modes ACL for bump and build workflow ([6fefab0](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/6fefab053bf748727078f2297426baf823ce8dab))
* **bump:** rename secret by  CI_GITHUB_TOKEN in bump and build workflow ([#21](https://github.com/Krossnine/terraform-aws-elastic-forwarder/issues/21)) ([13fe555](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/13fe55558b91e23be62d265f79b6f8af160abcf6))
* **ci:** remove debug cmds from bump and build workflow ([8711111](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/871111190635571feda1ef099e95e8559113b941))
* **deps-dev:** bump typescript from 4.9.5 to 5.1.3 in /lambda/src ([#6](https://github.com/Krossnine/terraform-aws-elastic-forwarder/issues/6)) ([d317258](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/d3172583bc9ae705cd4626ea0aa880a0b15f69b5))
* **deps:** bump esbuild from 0.14.54 to 0.18.0 in /lambda/src ([#14](https://github.com/Krossnine/terraform-aws-elastic-forwarder/issues/14)) ([a481e95](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/a481e95eab169005a9006afd708d6acd2c8511bf))
* **module:** bump elastic-forwarder module [skip ci] ([e386d7d](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/e386d7dc154aebc5261760536579bf2f5127a1ac))
* **module:** bump elastic-forwarder module [skip ci] ([29fc467](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/29fc4677eb206b4e96db3678d400c031b2cda9d3))
* **release:** 0.0.2 [skip ci] ([3e93806](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/3e938060c78cbec987f7deeb570f3ccb718fba46))
* **release:** 1.0.1 [skip ci] ([88d74db](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/88d74db1630671fe143093a56967a5005bffdac2))
* **release:** 1.0.1 [skip ci] ([22a3162](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/22a3162e9c6bd35b95307efcca04ef87de123dcf))
* **release:** 1.0.1 [skip ci] ([4989b5b](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/4989b5b44a310b60b20c0fa790b21218e8b37725))
* **release:** 1.0.1 [skip ci] ([df21b3d](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/df21b3dcd31c0388d7374ba78874e5e89c603706))
* **release:** add custom permission to release job ([5733a90](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/5733a902127fec9a826878f680bbd5c4e8af4410))
* **release:** deletion of duplicate jobs in error ([#13](https://github.com/Krossnine/terraform-aws-elastic-forwarder/issues/13)) ([ab503e2](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/ab503e2a17d714f09b66fa005e2bd79bd3d42c10))
* **release:** enable tag push ([21dcdda](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/21dcdda49443db8ea67b5cb7810d7fdf6e2432b7))
* **release:** make release latest by default ([ec4f5f6](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/ec4f5f66d7f1cea245422573043ca99bb673d706))
* **test-lambda:** add workflow exec on push to main ([a37c523](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/a37c5237793cef254d7968d01793d7d74830a823))
* **test:** add the ability to trigger  the integration test workflow manually ([520f740](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/520f7400810903056f478b35132ea05dd72a4c04))

### [0.0.2](https://github.com/Krossnine/terraform-aws-elastic-forwarder/compare/v0.0.1...v0.0.2) (2023-06-10)


### 🐛 Bug Fixes

* **lambda:** debug postbuild zip path ([3ee5053](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/3ee5053a7e209c06a9ae605bb6ebdc6eb472ac6a))


### 🏗  Chore

* **bump:** add fetch-depth param to checkout for semver ([5547b8f](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/5547b8ff62df911a6be5b4745a10fd07efc0a0fa))
* **ci:** remove debug cmds from bump and build workflow ([8711111](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/871111190635571feda1ef099e95e8559113b941))
* **deps-dev:** bump typescript from 4.9.5 to 5.1.3 in /lambda/src ([#6](https://github.com/Krossnine/terraform-aws-elastic-forwarder/issues/6)) ([d317258](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/d3172583bc9ae705cd4626ea0aa880a0b15f69b5))
* **module:** bump elastic-forwarder module [skip ci] ([e386d7d](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/e386d7dc154aebc5261760536579bf2f5127a1ac))
* **module:** bump elastic-forwarder module [skip ci] ([29fc467](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/29fc4677eb206b4e96db3678d400c031b2cda9d3))
* **release:** 1.0.1 [skip ci] ([88d74db](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/88d74db1630671fe143093a56967a5005bffdac2))
* **release:** 1.0.1 [skip ci] ([22a3162](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/22a3162e9c6bd35b95307efcca04ef87de123dcf))
* **release:** 1.0.1 [skip ci] ([4989b5b](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/4989b5b44a310b60b20c0fa790b21218e8b37725))
* **release:** 1.0.1 [skip ci] ([df21b3d](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/df21b3dcd31c0388d7374ba78874e5e89c603706))
* **release:** add custom permission to release job ([5733a90](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/5733a902127fec9a826878f680bbd5c4e8af4410))
* **release:** deletion of duplicate jobs in error ([#13](https://github.com/Krossnine/terraform-aws-elastic-forwarder/issues/13)) ([ab503e2](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/ab503e2a17d714f09b66fa005e2bd79bd3d42c10))
* **release:** enable tag push ([21dcdda](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/21dcdda49443db8ea67b5cb7810d7fdf6e2432b7))

### 1.0.1 (2023-06-10)


### 🏗  Chore

* **deps-dev:** bump typescript from 4.9.5 to 5.1.3 in /lambda/src ([#6](https://github.com/Krossnine/terraform-aws-elastic-forwarder/issues/6)) ([d317258](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/d3172583bc9ae705cd4626ea0aa880a0b15f69b5))

### 1.0.1 (2023-06-10)


### 🏗  Chore

* **release:** deletion of duplicate jobs in error ([#13](https://github.com/Krossnine/terraform-aws-elastic-forwarder/issues/13)) ([ab503e2](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/ab503e2a17d714f09b66fa005e2bd79bd3d42c10))

### 1.0.1 (2023-06-10)


### 🏗  Chore

* **release:** enable tag push ([21dcdda](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/21dcdda49443db8ea67b5cb7810d7fdf6e2432b7))

### 1.0.1 (2023-06-10)


### 🏗  Chore

* **release:** add custom permission to release job ([5733a90](https://github.com/Krossnine/terraform-aws-elastic-forwarder/commit/5733a902127fec9a826878f680bbd5c4e8af4410))
