# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Fixed
- Decoding File Metainfo with the Transfer Syntax UID not in the first chunk produced an error. By [@mch](https://github.com/mch)

### Added
-  CHANGELOG.md, more prominent documentation

## [0.4.3] - 2017-07-27
### Fixed
- Postinstall did not work on windows.

## [0.4.2] - 2016-07-31
### Fixed
- Problems with metadata content group length and fixed length sequences from a SIEMENS modality.

## [0.4.1] - 2015-05-21
### Added
- Support for VR US, by [@soichih](https://github.com/soichih).

## [0.4.0] - 2014-10-30
### Fixed
- Handling of empty elements at end of buffer

### Added
- Documentation in doc directory
- JSON Source emits DICOM Events, like DICOM Decoder
- Incomplete PDU Encoder/Decoder.  Stopped working on this because of QIDO-RS - I did not need this anymore.
- Possibly incomplete DICOM encoder. Was needed for PDU Encoder, status questionable but maybe useful to some.

[Unreleased]: https://github.com/grmble/node-dicom/compare/v0.4.3...HEAD
[0.4.3]: https://github.com/grmble/node-dicom/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/grmble/node-dicom/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/grmble/node-dicom/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/grmble/node-dicom/compare/v0.3.0...v0.4.0
