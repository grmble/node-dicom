#! /usr/bin/env coffee

vrs = require("./vrs")

##
#
# Dicom UID
#
##
class UID
  constructor: (@uid, @name, @typ) ->

##
#
# Transfer Syntax UID
#
##
class TransferSyntax extends UID
  endianess: () ->
    # only ExplicitVRBigEndian is big endian
    if /^ExplicitVRBigEndian/.test(@name) then vrs.BIG_ENDIAN else vrs.LITTLE_ENDIAN

  is_explicit: () ->
    not /^Implicit/.test(@name)

  make_context: () ->
    obj =
      endianess: @endianess()
      explicit: @is_explicit()
    return obj

  value_length_bytes: (vr) ->
    if @is_explicit() then vr.explicit_value_length_bytes else vr.implicit_value_length_bytes

class SOPClass extends UID

_make_uid = (uid, name, typ) ->
  constr = switch typ
    when 'TransferSyntax' then TransferSyntax
    when 'SOPClass' then SOPClass
    else UID
  new constr(uid, name, typ)

##
#
# Get a UID definitino by its symbolic uid or name
#
##
for_uid = (uid) ->
  _UID_DICT[uid] or exports[uid]

##
#
# find a UID
#
##
find = (regex) ->
  for uid, uidObj of _UID_DICT
    if regex.test(uid) or regex.test(uidObj.name)
      console.log uidObj
  undefined

exports.for_uid = for_uid
exports.find = find

# after the next line, everything is generated.  DO NOT MODIFY
# HERE BE DRAGONS
exports.VerificationSOPClass = _make_uid('1.2.840.10008.1.1', 'VerificationSOPClass', 'SOPClass')
exports.ImplicitVRLittleEndian = _make_uid('1.2.840.10008.1.2', 'ImplicitVRLittleEndian', 'TransferSyntax')
exports.ExplicitVRLittleEndian = _make_uid('1.2.840.10008.1.2.1', 'ExplicitVRLittleEndian', 'TransferSyntax')
exports.DeflatedExplicitVRLittleEndian = _make_uid('1.2.840.10008.1.2.1.99', 'DeflatedExplicitVRLittleEndian', 'TransferSyntax')
exports.ExplicitVRBigEndianRetired = _make_uid('1.2.840.10008.1.2.2', 'ExplicitVRBigEndianRetired', 'TransferSyntax')
exports.JPEGBaseline1 = _make_uid('1.2.840.10008.1.2.4.50', 'JPEGBaseline1', 'TransferSyntax')
exports.JPEGExtended24 = _make_uid('1.2.840.10008.1.2.4.51', 'JPEGExtended24', 'TransferSyntax')
exports.JPEGExtended35Retired = _make_uid('1.2.840.10008.1.2.4.52', 'JPEGExtended35Retired', 'TransferSyntax')
exports.JPEGSpectralSelectionNonHierarchical68Retired = _make_uid('1.2.840.10008.1.2.4.53', 'JPEGSpectralSelectionNonHierarchical68Retired', 'TransferSyntax')
exports.JPEGSpectralSelectionNonHierarchical79Retired = _make_uid('1.2.840.10008.1.2.4.54', 'JPEGSpectralSelectionNonHierarchical79Retired', 'TransferSyntax')
exports.JPEGFullProgressionNonHierarchical1012Retired = _make_uid('1.2.840.10008.1.2.4.55', 'JPEGFullProgressionNonHierarchical1012Retired', 'TransferSyntax')
exports.JPEGFullProgressionNonHierarchical1113Retired = _make_uid('1.2.840.10008.1.2.4.56', 'JPEGFullProgressionNonHierarchical1113Retired', 'TransferSyntax')
exports.JPEGLosslessNonHierarchical14 = _make_uid('1.2.840.10008.1.2.4.57', 'JPEGLosslessNonHierarchical14', 'TransferSyntax')
exports.JPEGLosslessNonHierarchical15Retired = _make_uid('1.2.840.10008.1.2.4.58', 'JPEGLosslessNonHierarchical15Retired', 'TransferSyntax')
exports.JPEGExtendedHierarchical1618Retired = _make_uid('1.2.840.10008.1.2.4.59', 'JPEGExtendedHierarchical1618Retired', 'TransferSyntax')
exports.JPEGExtendedHierarchical1719Retired = _make_uid('1.2.840.10008.1.2.4.60', 'JPEGExtendedHierarchical1719Retired', 'TransferSyntax')
exports.JPEGSpectralSelectionHierarchical2022Retired = _make_uid('1.2.840.10008.1.2.4.61', 'JPEGSpectralSelectionHierarchical2022Retired', 'TransferSyntax')
exports.JPEGSpectralSelectionHierarchical2123Retired = _make_uid('1.2.840.10008.1.2.4.62', 'JPEGSpectralSelectionHierarchical2123Retired', 'TransferSyntax')
exports.JPEGFullProgressionHierarchical2426Retired = _make_uid('1.2.840.10008.1.2.4.63', 'JPEGFullProgressionHierarchical2426Retired', 'TransferSyntax')
exports.JPEGFullProgressionHierarchical2527Retired = _make_uid('1.2.840.10008.1.2.4.64', 'JPEGFullProgressionHierarchical2527Retired', 'TransferSyntax')
exports.JPEGLosslessHierarchical28Retired = _make_uid('1.2.840.10008.1.2.4.65', 'JPEGLosslessHierarchical28Retired', 'TransferSyntax')
exports.JPEGLosslessHierarchical29Retired = _make_uid('1.2.840.10008.1.2.4.66', 'JPEGLosslessHierarchical29Retired', 'TransferSyntax')
exports.JPEGLossless = _make_uid('1.2.840.10008.1.2.4.70', 'JPEGLossless', 'TransferSyntax')
exports.JPEGLSLossless = _make_uid('1.2.840.10008.1.2.4.80', 'JPEGLSLossless', 'TransferSyntax')
exports.JPEGLSLossyNearLossless = _make_uid('1.2.840.10008.1.2.4.81', 'JPEGLSLossyNearLossless', 'TransferSyntax')
exports.JPEG2000LosslessOnly = _make_uid('1.2.840.10008.1.2.4.90', 'JPEG2000LosslessOnly', 'TransferSyntax')
exports.JPEG2000 = _make_uid('1.2.840.10008.1.2.4.91', 'JPEG2000', 'TransferSyntax')
exports.JPEG2000Part2MultiComponentLosslessOnly = _make_uid('1.2.840.10008.1.2.4.92', 'JPEG2000Part2MultiComponentLosslessOnly', 'TransferSyntax')
exports.JPEG2000Part2MultiComponent = _make_uid('1.2.840.10008.1.2.4.93', 'JPEG2000Part2MultiComponent', 'TransferSyntax')
exports.JPIPReferenced = _make_uid('1.2.840.10008.1.2.4.94', 'JPIPReferenced', 'TransferSyntax')
exports.JPIPReferencedDeflate = _make_uid('1.2.840.10008.1.2.4.95', 'JPIPReferencedDeflate', 'TransferSyntax')
exports.MPEG2 = _make_uid('1.2.840.10008.1.2.4.100', 'MPEG2', 'TransferSyntax')
exports.MPEG2MainProfileHighLevel = _make_uid('1.2.840.10008.1.2.4.101', 'MPEG2MainProfileHighLevel', 'TransferSyntax')
exports.MPEG4AVCH264HighProfileLevel41 = _make_uid('1.2.840.10008.1.2.4.102', 'MPEG4AVCH264HighProfileLevel41', 'TransferSyntax')
exports.MPEG4AVCH264BDCompatibleHighProfileLevel41 = _make_uid('1.2.840.10008.1.2.4.103', 'MPEG4AVCH264BDCompatibleHighProfileLevel41', 'TransferSyntax')
exports.RLELossless = _make_uid('1.2.840.10008.1.2.5', 'RLELossless', 'TransferSyntax')
exports.RFC2557MIMEEncapsulation = _make_uid('1.2.840.10008.1.2.6.1', 'RFC2557MIMEEncapsulation', 'TransferSyntax')
exports.XMLEncoding = _make_uid('1.2.840.10008.1.2.6.2', 'XMLEncoding', 'TransferSyntax')
exports.MediaStorageDirectoryStorage = _make_uid('1.2.840.10008.1.3.10', 'MediaStorageDirectoryStorage', 'SOPClass')
exports.TalairachBrainAtlasFrameOfReference = _make_uid('1.2.840.10008.1.4.1.1', 'TalairachBrainAtlasFrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2T1FrameOfReference = _make_uid('1.2.840.10008.1.4.1.2', 'SPM2T1FrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2T2FrameOfReference = _make_uid('1.2.840.10008.1.4.1.3', 'SPM2T2FrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2PDFrameOfReference = _make_uid('1.2.840.10008.1.4.1.4', 'SPM2PDFrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2EPIFrameOfReference = _make_uid('1.2.840.10008.1.4.1.5', 'SPM2EPIFrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2FILT1FrameOfReference = _make_uid('1.2.840.10008.1.4.1.6', 'SPM2FILT1FrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2PETFrameOfReference = _make_uid('1.2.840.10008.1.4.1.7', 'SPM2PETFrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2TRANSMFrameOfReference = _make_uid('1.2.840.10008.1.4.1.8', 'SPM2TRANSMFrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2SPECTFrameOfReference = _make_uid('1.2.840.10008.1.4.1.9', 'SPM2SPECTFrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2GRAYFrameOfReference = _make_uid('1.2.840.10008.1.4.1.10', 'SPM2GRAYFrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2WHITEFrameOfReference = _make_uid('1.2.840.10008.1.4.1.11', 'SPM2WHITEFrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2CSFFrameOfReference = _make_uid('1.2.840.10008.1.4.1.12', 'SPM2CSFFrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2BRAINMASKFrameOfReference = _make_uid('1.2.840.10008.1.4.1.13', 'SPM2BRAINMASKFrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2AVG305T1FrameOfReference = _make_uid('1.2.840.10008.1.4.1.14', 'SPM2AVG305T1FrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2AVG152T1FrameOfReference = _make_uid('1.2.840.10008.1.4.1.15', 'SPM2AVG152T1FrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2AVG152T2FrameOfReference = _make_uid('1.2.840.10008.1.4.1.16', 'SPM2AVG152T2FrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2AVG152PDFrameOfReference = _make_uid('1.2.840.10008.1.4.1.17', 'SPM2AVG152PDFrameOfReference', 'WellKnownFrameOfReference')
exports.SPM2SINGLESUBJT1FrameOfReference = _make_uid('1.2.840.10008.1.4.1.18', 'SPM2SINGLESUBJT1FrameOfReference', 'WellKnownFrameOfReference')
exports.ICBM452T1FrameOfReference = _make_uid('1.2.840.10008.1.4.2.1', 'ICBM452T1FrameOfReference', 'WellKnownFrameOfReference')
exports.ICBMSingleSubjectMRIFrameOfReference = _make_uid('1.2.840.10008.1.4.2.2', 'ICBMSingleSubjectMRIFrameOfReference', 'WellKnownFrameOfReference')
exports.HotIronColorPaletteSOPInstance = _make_uid('1.2.840.10008.1.5.1', 'HotIronColorPaletteSOPInstance', 'WellKnownSOPInstance')
exports.PETColorPaletteSOPInstance = _make_uid('1.2.840.10008.1.5.2', 'PETColorPaletteSOPInstance', 'WellKnownSOPInstance')
exports.HotMetalBlueColorPaletteSOPInstance = _make_uid('1.2.840.10008.1.5.3', 'HotMetalBlueColorPaletteSOPInstance', 'WellKnownSOPInstance')
exports.PET20StepColorPaletteSOPInstance = _make_uid('1.2.840.10008.1.5.4', 'PET20StepColorPaletteSOPInstance', 'WellKnownSOPInstance')
exports.BasicStudyContentNotificationSOPClassRetired = _make_uid('1.2.840.10008.1.9', 'BasicStudyContentNotificationSOPClassRetired', 'SOPClass')
exports.StorageCommitmentPushModelSOPClass = _make_uid('1.2.840.10008.1.20.1', 'StorageCommitmentPushModelSOPClass', 'SOPClass')
exports.StorageCommitmentPushModelSOPInstance = _make_uid('1.2.840.10008.1.20.1.1', 'StorageCommitmentPushModelSOPInstance', 'WellKnownSOPInstance')
exports.StorageCommitmentPullModelSOPClassRetired = _make_uid('1.2.840.10008.1.20.2', 'StorageCommitmentPullModelSOPClassRetired', 'SOPClass')
exports.StorageCommitmentPullModelSOPInstanceRetired = _make_uid('1.2.840.10008.1.20.2.1', 'StorageCommitmentPullModelSOPInstanceRetired', 'WellKnownSOPInstance')
exports.ProceduralEventLoggingSOPClass = _make_uid('1.2.840.10008.1.40', 'ProceduralEventLoggingSOPClass', 'SOPClass')
exports.ProceduralEventLoggingSOPInstance = _make_uid('1.2.840.10008.1.40.1', 'ProceduralEventLoggingSOPInstance', 'WellKnownSOPInstance')
exports.SubstanceAdministrationLoggingSOPClass = _make_uid('1.2.840.10008.1.42', 'SubstanceAdministrationLoggingSOPClass', 'SOPClass')
exports.SubstanceAdministrationLoggingSOPInstance = _make_uid('1.2.840.10008.1.42.1', 'SubstanceAdministrationLoggingSOPInstance', 'WellKnownSOPInstance')
exports.DICOMUIDRegistry = _make_uid('1.2.840.10008.2.6.1', 'DICOMUIDRegistry', 'DICOMUIDsAsACodingScheme')
exports.DICOMControlledTerminology = _make_uid('1.2.840.10008.2.16.4', 'DICOMControlledTerminology', 'CodingScheme')
exports.DICOMApplicationContextName = _make_uid('1.2.840.10008.3.1.1.1', 'DICOMApplicationContextName', 'ApplicationContextName')
exports.DetachedPatientManagementSOPClassRetired = _make_uid('1.2.840.10008.3.1.2.1.1', 'DetachedPatientManagementSOPClassRetired', 'SOPClass')
exports.DetachedPatientManagementMetaSOPClassRetired = _make_uid('1.2.840.10008.3.1.2.1.4', 'DetachedPatientManagementMetaSOPClassRetired', 'MetaSOPClass')
exports.DetachedVisitManagementSOPClassRetired = _make_uid('1.2.840.10008.3.1.2.2.1', 'DetachedVisitManagementSOPClassRetired', 'SOPClass')
exports.DetachedStudyManagementSOPClassRetired = _make_uid('1.2.840.10008.3.1.2.3.1', 'DetachedStudyManagementSOPClassRetired', 'SOPClass')
exports.StudyComponentManagementSOPClassRetired = _make_uid('1.2.840.10008.3.1.2.3.2', 'StudyComponentManagementSOPClassRetired', 'SOPClass')
exports.ModalityPerformedProcedureStepSOPClass = _make_uid('1.2.840.10008.3.1.2.3.3', 'ModalityPerformedProcedureStepSOPClass', 'SOPClass')
exports.ModalityPerformedProcedureStepRetrieveSOPClass = _make_uid('1.2.840.10008.3.1.2.3.4', 'ModalityPerformedProcedureStepRetrieveSOPClass', 'SOPClass')
exports.ModalityPerformedProcedureStepNotificationSOPClass = _make_uid('1.2.840.10008.3.1.2.3.5', 'ModalityPerformedProcedureStepNotificationSOPClass', 'SOPClass')
exports.DetachedResultsManagementSOPClassRetired = _make_uid('1.2.840.10008.3.1.2.5.1', 'DetachedResultsManagementSOPClassRetired', 'SOPClass')
exports.DetachedResultsManagementMetaSOPClassRetired = _make_uid('1.2.840.10008.3.1.2.5.4', 'DetachedResultsManagementMetaSOPClassRetired', 'MetaSOPClass')
exports.DetachedStudyManagementMetaSOPClassRetired = _make_uid('1.2.840.10008.3.1.2.5.5', 'DetachedStudyManagementMetaSOPClassRetired', 'MetaSOPClass')
exports.DetachedInterpretationManagementSOPClassRetired = _make_uid('1.2.840.10008.3.1.2.6.1', 'DetachedInterpretationManagementSOPClassRetired', 'SOPClass')
exports.StorageServiceClass = _make_uid('1.2.840.10008.4.2', 'StorageServiceClass', 'ServiceClass')
exports.BasicFilmSessionSOPClass = _make_uid('1.2.840.10008.5.1.1.1', 'BasicFilmSessionSOPClass', 'SOPClass')
exports.BasicFilmBoxSOPClass = _make_uid('1.2.840.10008.5.1.1.2', 'BasicFilmBoxSOPClass', 'SOPClass')
exports.BasicGrayscaleImageBoxSOPClass = _make_uid('1.2.840.10008.5.1.1.4', 'BasicGrayscaleImageBoxSOPClass', 'SOPClass')
exports.BasicColorImageBoxSOPClass = _make_uid('1.2.840.10008.5.1.1.4.1', 'BasicColorImageBoxSOPClass', 'SOPClass')
exports.ReferencedImageBoxSOPClassRetired = _make_uid('1.2.840.10008.5.1.1.4.2', 'ReferencedImageBoxSOPClassRetired', 'SOPClass')
exports.BasicGrayscalePrintManagementMetaSOPClass = _make_uid('1.2.840.10008.5.1.1.9', 'BasicGrayscalePrintManagementMetaSOPClass', 'MetaSOPClass')
exports.ReferencedGrayscalePrintManagementMetaSOPClassRetired = _make_uid('1.2.840.10008.5.1.1.9.1', 'ReferencedGrayscalePrintManagementMetaSOPClassRetired', 'MetaSOPClass')
exports.PrintJobSOPClass = _make_uid('1.2.840.10008.5.1.1.14', 'PrintJobSOPClass', 'SOPClass')
exports.BasicAnnotationBoxSOPClass = _make_uid('1.2.840.10008.5.1.1.15', 'BasicAnnotationBoxSOPClass', 'SOPClass')
exports.PrinterSOPClass = _make_uid('1.2.840.10008.5.1.1.16', 'PrinterSOPClass', 'SOPClass')
exports.PrinterConfigurationRetrievalSOPClass = _make_uid('1.2.840.10008.5.1.1.16.376', 'PrinterConfigurationRetrievalSOPClass', 'SOPClass')
exports.PrinterSOPInstance = _make_uid('1.2.840.10008.5.1.1.17', 'PrinterSOPInstance', 'WellKnownPrinterSOPInstance')
exports.PrinterConfigurationRetrievalSOPInstance = _make_uid('1.2.840.10008.5.1.1.17.376', 'PrinterConfigurationRetrievalSOPInstance', 'WellKnownPrinterSOPInstance')
exports.BasicColorPrintManagementMetaSOPClass = _make_uid('1.2.840.10008.5.1.1.18', 'BasicColorPrintManagementMetaSOPClass', 'MetaSOPClass')
exports.ReferencedColorPrintManagementMetaSOPClassRetired = _make_uid('1.2.840.10008.5.1.1.18.1', 'ReferencedColorPrintManagementMetaSOPClassRetired', 'MetaSOPClass')
exports.VOILUTBoxSOPClass = _make_uid('1.2.840.10008.5.1.1.22', 'VOILUTBoxSOPClass', 'SOPClass')
exports.PresentationLUTSOPClass = _make_uid('1.2.840.10008.5.1.1.23', 'PresentationLUTSOPClass', 'SOPClass')
exports.ImageOverlayBoxSOPClassRetired = _make_uid('1.2.840.10008.5.1.1.24', 'ImageOverlayBoxSOPClassRetired', 'SOPClass')
exports.BasicPrintImageOverlayBoxSOPClassRetired = _make_uid('1.2.840.10008.5.1.1.24.1', 'BasicPrintImageOverlayBoxSOPClassRetired', 'SOPClass')
exports.PrintQueueSOPInstanceRetired = _make_uid('1.2.840.10008.5.1.1.25', 'PrintQueueSOPInstanceRetired', 'WellKnownPrintQueueSOPInstance')
exports.PrintQueueManagementSOPClassRetired = _make_uid('1.2.840.10008.5.1.1.26', 'PrintQueueManagementSOPClassRetired', 'SOPClass')
exports.StoredPrintStorageSOPClassRetired = _make_uid('1.2.840.10008.5.1.1.27', 'StoredPrintStorageSOPClassRetired', 'SOPClass')
exports.HardcopyGrayscaleImageStorageSOPClassRetired = _make_uid('1.2.840.10008.5.1.1.29', 'HardcopyGrayscaleImageStorageSOPClassRetired', 'SOPClass')
exports.HardcopyColorImageStorageSOPClassRetired = _make_uid('1.2.840.10008.5.1.1.30', 'HardcopyColorImageStorageSOPClassRetired', 'SOPClass')
exports.PullPrintRequestSOPClassRetired = _make_uid('1.2.840.10008.5.1.1.31', 'PullPrintRequestSOPClassRetired', 'SOPClass')
exports.PullStoredPrintManagementMetaSOPClassRetired = _make_uid('1.2.840.10008.5.1.1.32', 'PullStoredPrintManagementMetaSOPClassRetired', 'MetaSOPClass')
exports.MediaCreationManagementSOPClassUID = _make_uid('1.2.840.10008.5.1.1.33', 'MediaCreationManagementSOPClassUID', 'SOPClass')
exports.DisplaySystemSOPClass = _make_uid('1.2.840.10008.5.1.1.40', 'DisplaySystemSOPClass', 'SOPClass')
exports.DisplaySystemSOPInstance = _make_uid('1.2.840.10008.5.1.1.40.1', 'DisplaySystemSOPInstance', 'WellKnownSOPInstance')
exports.ComputedRadiographyImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.1', 'ComputedRadiographyImageStorage', 'SOPClass')
exports.DigitalXRayImageStorageForPresentation = _make_uid('1.2.840.10008.5.1.4.1.1.1.1', 'DigitalXRayImageStorageForPresentation', 'SOPClass')
exports.DigitalXRayImageStorageForProcessing = _make_uid('1.2.840.10008.5.1.4.1.1.1.1.1', 'DigitalXRayImageStorageForProcessing', 'SOPClass')
exports.DigitalMammographyXRayImageStorageForPresentation = _make_uid('1.2.840.10008.5.1.4.1.1.1.2', 'DigitalMammographyXRayImageStorageForPresentation', 'SOPClass')
exports.DigitalMammographyXRayImageStorageForProcessing = _make_uid('1.2.840.10008.5.1.4.1.1.1.2.1', 'DigitalMammographyXRayImageStorageForProcessing', 'SOPClass')
exports.DigitalIntraOralXRayImageStorageForPresentation = _make_uid('1.2.840.10008.5.1.4.1.1.1.3', 'DigitalIntraOralXRayImageStorageForPresentation', 'SOPClass')
exports.DigitalIntraOralXRayImageStorageForProcessing = _make_uid('1.2.840.10008.5.1.4.1.1.1.3.1', 'DigitalIntraOralXRayImageStorageForProcessing', 'SOPClass')
exports.CTImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.2', 'CTImageStorage', 'SOPClass')
exports.EnhancedCTImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.2.1', 'EnhancedCTImageStorage', 'SOPClass')
exports.LegacyConvertedEnhancedCTImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.2.2', 'LegacyConvertedEnhancedCTImageStorage', 'SOPClass')
exports.UltrasoundMultiFrameImageStorageRetired = _make_uid('1.2.840.10008.5.1.4.1.1.3', 'UltrasoundMultiFrameImageStorageRetired', 'SOPClass')
exports.UltrasoundMultiFrameImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.3.1', 'UltrasoundMultiFrameImageStorage', 'SOPClass')
exports.MRImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.4', 'MRImageStorage', 'SOPClass')
exports.EnhancedMRImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.4.1', 'EnhancedMRImageStorage', 'SOPClass')
exports.MRSpectroscopyStorage = _make_uid('1.2.840.10008.5.1.4.1.1.4.2', 'MRSpectroscopyStorage', 'SOPClass')
exports.EnhancedMRColorImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.4.3', 'EnhancedMRColorImageStorage', 'SOPClass')
exports.LegacyConvertedEnhancedMRImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.4.4', 'LegacyConvertedEnhancedMRImageStorage', 'SOPClass')
exports.NuclearMedicineImageStorageRetired = _make_uid('1.2.840.10008.5.1.4.1.1.5', 'NuclearMedicineImageStorageRetired', 'SOPClass')
exports.UltrasoundImageStorageRetired = _make_uid('1.2.840.10008.5.1.4.1.1.6', 'UltrasoundImageStorageRetired', 'SOPClass')
exports.UltrasoundImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.6.1', 'UltrasoundImageStorage', 'SOPClass')
exports.EnhancedUSVolumeStorage = _make_uid('1.2.840.10008.5.1.4.1.1.6.2', 'EnhancedUSVolumeStorage', 'SOPClass')
exports.SecondaryCaptureImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.7', 'SecondaryCaptureImageStorage', 'SOPClass')
exports.MultiFrameSingleBitSecondaryCaptureImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.7.1', 'MultiFrameSingleBitSecondaryCaptureImageStorage', 'SOPClass')
exports.MultiFrameGrayscaleByteSecondaryCaptureImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.7.2', 'MultiFrameGrayscaleByteSecondaryCaptureImageStorage', 'SOPClass')
exports.MultiFrameGrayscaleWordSecondaryCaptureImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.7.3', 'MultiFrameGrayscaleWordSecondaryCaptureImageStorage', 'SOPClass')
exports.MultiFrameTrueColorSecondaryCaptureImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.7.4', 'MultiFrameTrueColorSecondaryCaptureImageStorage', 'SOPClass')
exports.StandaloneOverlayStorageRetired = _make_uid('1.2.840.10008.5.1.4.1.1.8', 'StandaloneOverlayStorageRetired', 'SOPClass')
exports.StandaloneCurveStorageRetired = _make_uid('1.2.840.10008.5.1.4.1.1.9', 'StandaloneCurveStorageRetired', 'SOPClass')
exports.WaveformStorageTrialRetired = _make_uid('1.2.840.10008.5.1.4.1.1.9.1', 'WaveformStorageTrialRetired', 'SOPClass')
exports.TwelveLeadECGWaveformStorage = _make_uid('1.2.840.10008.5.1.4.1.1.9.1.1', 'TwelveLeadECGWaveformStorage', 'SOPClass')
exports.GeneralECGWaveformStorage = _make_uid('1.2.840.10008.5.1.4.1.1.9.1.2', 'GeneralECGWaveformStorage', 'SOPClass')
exports.AmbulatoryECGWaveformStorage = _make_uid('1.2.840.10008.5.1.4.1.1.9.1.3', 'AmbulatoryECGWaveformStorage', 'SOPClass')
exports.HemodynamicWaveformStorage = _make_uid('1.2.840.10008.5.1.4.1.1.9.2.1', 'HemodynamicWaveformStorage', 'SOPClass')
exports.CardiacElectrophysiologyWaveformStorage = _make_uid('1.2.840.10008.5.1.4.1.1.9.3.1', 'CardiacElectrophysiologyWaveformStorage', 'SOPClass')
exports.BasicVoiceAudioWaveformStorage = _make_uid('1.2.840.10008.5.1.4.1.1.9.4.1', 'BasicVoiceAudioWaveformStorage', 'SOPClass')
exports.GeneralAudioWaveformStorage = _make_uid('1.2.840.10008.5.1.4.1.1.9.4.2', 'GeneralAudioWaveformStorage', 'SOPClass')
exports.ArterialPulseWaveformStorage = _make_uid('1.2.840.10008.5.1.4.1.1.9.5.1', 'ArterialPulseWaveformStorage', 'SOPClass')
exports.RespiratoryWaveformStorage = _make_uid('1.2.840.10008.5.1.4.1.1.9.6.1', 'RespiratoryWaveformStorage', 'SOPClass')
exports.StandaloneModalityLUTStorageRetired = _make_uid('1.2.840.10008.5.1.4.1.1.10', 'StandaloneModalityLUTStorageRetired', 'SOPClass')
exports.StandaloneVOILUTStorageRetired = _make_uid('1.2.840.10008.5.1.4.1.1.11', 'StandaloneVOILUTStorageRetired', 'SOPClass')
exports.GrayscaleSoftcopyPresentationStateStorageSOPClass = _make_uid('1.2.840.10008.5.1.4.1.1.11.1', 'GrayscaleSoftcopyPresentationStateStorageSOPClass', 'SOPClass')
exports.ColorSoftcopyPresentationStateStorageSOPClass = _make_uid('1.2.840.10008.5.1.4.1.1.11.2', 'ColorSoftcopyPresentationStateStorageSOPClass', 'SOPClass')
exports.PseudoColorSoftcopyPresentationStateStorageSOPClass = _make_uid('1.2.840.10008.5.1.4.1.1.11.3', 'PseudoColorSoftcopyPresentationStateStorageSOPClass', 'SOPClass')
exports.BlendingSoftcopyPresentationStateStorageSOPClass = _make_uid('1.2.840.10008.5.1.4.1.1.11.4', 'BlendingSoftcopyPresentationStateStorageSOPClass', 'SOPClass')
exports.XAXRFGrayscaleSoftcopyPresentationStateStorage = _make_uid('1.2.840.10008.5.1.4.1.1.11.5', 'XAXRFGrayscaleSoftcopyPresentationStateStorage', 'SOPClass')
exports.XRayAngiographicImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.12.1', 'XRayAngiographicImageStorage', 'SOPClass')
exports.EnhancedXAImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.12.1.1', 'EnhancedXAImageStorage', 'SOPClass')
exports.XRayRadiofluoroscopicImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.12.2', 'XRayRadiofluoroscopicImageStorage', 'SOPClass')
exports.EnhancedXRFImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.12.2.1', 'EnhancedXRFImageStorage', 'SOPClass')
exports.XRayAngiographicBiPlaneImageStorageRetired = _make_uid('1.2.840.10008.5.1.4.1.1.12.3', 'XRayAngiographicBiPlaneImageStorageRetired', 'SOPClass')
exports.XRay3DAngiographicImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.13.1.1', 'XRay3DAngiographicImageStorage', 'SOPClass')
exports.XRay3DCraniofacialImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.13.1.2', 'XRay3DCraniofacialImageStorage', 'SOPClass')
exports.BreastTomosynthesisImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.13.1.3', 'BreastTomosynthesisImageStorage', 'SOPClass')
exports.BreastProjectionXRayImageStorageForPresentation = _make_uid('1.2.840.10008.5.1.4.1.1.13.1.4', 'BreastProjectionXRayImageStorageForPresentation', 'SOPClass')
exports.BreastProjectionXRayImageStorageForProcessing = _make_uid('1.2.840.10008.5.1.4.1.1.13.1.5', 'BreastProjectionXRayImageStorageForProcessing', 'SOPClass')
exports.IntravascularOpticalCoherenceTomographyImageStorageForPresentation = _make_uid('1.2.840.10008.5.1.4.1.1.14.1', 'IntravascularOpticalCoherenceTomographyImageStorageForPresentation', 'SOPClass')
exports.IntravascularOpticalCoherenceTomographyImageStorageForProcessing = _make_uid('1.2.840.10008.5.1.4.1.1.14.2', 'IntravascularOpticalCoherenceTomographyImageStorageForProcessing', 'SOPClass')
exports.NuclearMedicineImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.20', 'NuclearMedicineImageStorage', 'SOPClass')
exports.RawDataStorage = _make_uid('1.2.840.10008.5.1.4.1.1.66', 'RawDataStorage', 'SOPClass')
exports.SpatialRegistrationStorage = _make_uid('1.2.840.10008.5.1.4.1.1.66.1', 'SpatialRegistrationStorage', 'SOPClass')
exports.SpatialFiducialsStorage = _make_uid('1.2.840.10008.5.1.4.1.1.66.2', 'SpatialFiducialsStorage', 'SOPClass')
exports.DeformableSpatialRegistrationStorage = _make_uid('1.2.840.10008.5.1.4.1.1.66.3', 'DeformableSpatialRegistrationStorage', 'SOPClass')
exports.SegmentationStorage = _make_uid('1.2.840.10008.5.1.4.1.1.66.4', 'SegmentationStorage', 'SOPClass')
exports.SurfaceSegmentationStorage = _make_uid('1.2.840.10008.5.1.4.1.1.66.5', 'SurfaceSegmentationStorage', 'SOPClass')
exports.RealWorldValueMappingStorage = _make_uid('1.2.840.10008.5.1.4.1.1.67', 'RealWorldValueMappingStorage', 'SOPClass')
exports.SurfaceScanMeshStorage = _make_uid('1.2.840.10008.5.1.4.1.1.68.1', 'SurfaceScanMeshStorage', 'SOPClass')
exports.SurfaceScanPointCloudStorage = _make_uid('1.2.840.10008.5.1.4.1.1.68.2', 'SurfaceScanPointCloudStorage', 'SOPClass')
exports.VLImageStorageTrialRetired = _make_uid('1.2.840.10008.5.1.4.1.1.77.1', 'VLImageStorageTrialRetired', 'SOPClass')
exports.VLMultiFrameImageStorageTrialRetired = _make_uid('1.2.840.10008.5.1.4.1.1.77.2', 'VLMultiFrameImageStorageTrialRetired', 'SOPClass')
exports.VLEndoscopicImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.1', 'VLEndoscopicImageStorage', 'SOPClass')
exports.VideoEndoscopicImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.1.1', 'VideoEndoscopicImageStorage', 'SOPClass')
exports.VLMicroscopicImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.2', 'VLMicroscopicImageStorage', 'SOPClass')
exports.VideoMicroscopicImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.2.1', 'VideoMicroscopicImageStorage', 'SOPClass')
exports.VLSlideCoordinatesMicroscopicImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.3', 'VLSlideCoordinatesMicroscopicImageStorage', 'SOPClass')
exports.VLPhotographicImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.4', 'VLPhotographicImageStorage', 'SOPClass')
exports.VideoPhotographicImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.4.1', 'VideoPhotographicImageStorage', 'SOPClass')
exports.OphthalmicPhotography8BitImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.5.1', 'OphthalmicPhotography8BitImageStorage', 'SOPClass')
exports.OphthalmicPhotography16BitImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.5.2', 'OphthalmicPhotography16BitImageStorage', 'SOPClass')
exports.StereometricRelationshipStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.5.3', 'StereometricRelationshipStorage', 'SOPClass')
exports.OphthalmicTomographyImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.5.4', 'OphthalmicTomographyImageStorage', 'SOPClass')
exports.VLWholeSlideMicroscopyImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.77.1.6', 'VLWholeSlideMicroscopyImageStorage', 'SOPClass')
exports.LensometryMeasurementsStorage = _make_uid('1.2.840.10008.5.1.4.1.1.78.1', 'LensometryMeasurementsStorage', 'SOPClass')
exports.AutorefractionMeasurementsStorage = _make_uid('1.2.840.10008.5.1.4.1.1.78.2', 'AutorefractionMeasurementsStorage', 'SOPClass')
exports.KeratometryMeasurementsStorage = _make_uid('1.2.840.10008.5.1.4.1.1.78.3', 'KeratometryMeasurementsStorage', 'SOPClass')
exports.SubjectiveRefractionMeasurementsStorage = _make_uid('1.2.840.10008.5.1.4.1.1.78.4', 'SubjectiveRefractionMeasurementsStorage', 'SOPClass')
exports.VisualAcuityMeasurementsStorage = _make_uid('1.2.840.10008.5.1.4.1.1.78.5', 'VisualAcuityMeasurementsStorage', 'SOPClass')
exports.SpectaclePrescriptionReportStorage = _make_uid('1.2.840.10008.5.1.4.1.1.78.6', 'SpectaclePrescriptionReportStorage', 'SOPClass')
exports.OphthalmicAxialMeasurementsStorage = _make_uid('1.2.840.10008.5.1.4.1.1.78.7', 'OphthalmicAxialMeasurementsStorage', 'SOPClass')
exports.IntraocularLensCalculationsStorage = _make_uid('1.2.840.10008.5.1.4.1.1.78.8', 'IntraocularLensCalculationsStorage', 'SOPClass')
exports.MacularGridThicknessAndVolumeReportStorage = _make_uid('1.2.840.10008.5.1.4.1.1.79.1', 'MacularGridThicknessAndVolumeReportStorage', 'SOPClass')
exports.OphthalmicVisualFieldStaticPerimetryMeasurementsStorage = _make_uid('1.2.840.10008.5.1.4.1.1.80.1', 'OphthalmicVisualFieldStaticPerimetryMeasurementsStorage', 'SOPClass')
exports.OphthalmicThicknessMapStorage = _make_uid('1.2.840.10008.5.1.4.1.1.81.1', 'OphthalmicThicknessMapStorage', 'SOPClass')
exports.CornealTopographyMapStorage = _make_uid('1.2.840.10008.5.1.4.1.1.82.1', 'CornealTopographyMapStorage', 'SOPClass')
exports.TextSRStorageTrialRetired = _make_uid('1.2.840.10008.5.1.4.1.1.88.1', 'TextSRStorageTrialRetired', 'SOPClass')
exports.AudioSRStorageTrialRetired = _make_uid('1.2.840.10008.5.1.4.1.1.88.2', 'AudioSRStorageTrialRetired', 'SOPClass')
exports.DetailSRStorageTrialRetired = _make_uid('1.2.840.10008.5.1.4.1.1.88.3', 'DetailSRStorageTrialRetired', 'SOPClass')
exports.ComprehensiveSRStorageTrialRetired = _make_uid('1.2.840.10008.5.1.4.1.1.88.4', 'ComprehensiveSRStorageTrialRetired', 'SOPClass')
exports.BasicTextSRStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.11', 'BasicTextSRStorage', 'SOPClass')
exports.EnhancedSRStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.22', 'EnhancedSRStorage', 'SOPClass')
exports.ComprehensiveSRStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.33', 'ComprehensiveSRStorage', 'SOPClass')
exports.Comprehensive3DSRStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.34', 'Comprehensive3DSRStorage', 'SOPClass')
exports.ProcedureLogStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.40', 'ProcedureLogStorage', 'SOPClass')
exports.MammographyCADSRStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.50', 'MammographyCADSRStorage', 'SOPClass')
exports.KeyObjectSelectionDocumentStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.59', 'KeyObjectSelectionDocumentStorage', 'SOPClass')
exports.ChestCADSRStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.65', 'ChestCADSRStorage', 'SOPClass')
exports.XRayRadiationDoseSRStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.67', 'XRayRadiationDoseSRStorage', 'SOPClass')
exports.RadiopharmaceuticalRadiationDoseSRStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.68', 'RadiopharmaceuticalRadiationDoseSRStorage', 'SOPClass')
exports.ColonCADSRStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.69', 'ColonCADSRStorage', 'SOPClass')
exports.ImplantationPlanSRStorage = _make_uid('1.2.840.10008.5.1.4.1.1.88.70', 'ImplantationPlanSRStorage', 'SOPClass')
exports.EncapsulatedPDFStorage = _make_uid('1.2.840.10008.5.1.4.1.1.104.1', 'EncapsulatedPDFStorage', 'SOPClass')
exports.EncapsulatedCDAStorage = _make_uid('1.2.840.10008.5.1.4.1.1.104.2', 'EncapsulatedCDAStorage', 'SOPClass')
exports.PositronEmissionTomographyImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.128', 'PositronEmissionTomographyImageStorage', 'SOPClass')
exports.LegacyConvertedEnhancedPETImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.128.1', 'LegacyConvertedEnhancedPETImageStorage', 'SOPClass')
exports.StandalonePETCurveStorageRetired = _make_uid('1.2.840.10008.5.1.4.1.1.129', 'StandalonePETCurveStorageRetired', 'SOPClass')
exports.EnhancedPETImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.130', 'EnhancedPETImageStorage', 'SOPClass')
exports.BasicStructuredDisplayStorage = _make_uid('1.2.840.10008.5.1.4.1.1.131', 'BasicStructuredDisplayStorage', 'SOPClass')
exports.RTImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.481.1', 'RTImageStorage', 'SOPClass')
exports.RTDoseStorage = _make_uid('1.2.840.10008.5.1.4.1.1.481.2', 'RTDoseStorage', 'SOPClass')
exports.RTStructureSetStorage = _make_uid('1.2.840.10008.5.1.4.1.1.481.3', 'RTStructureSetStorage', 'SOPClass')
exports.RTBeamsTreatmentRecordStorage = _make_uid('1.2.840.10008.5.1.4.1.1.481.4', 'RTBeamsTreatmentRecordStorage', 'SOPClass')
exports.RTPlanStorage = _make_uid('1.2.840.10008.5.1.4.1.1.481.5', 'RTPlanStorage', 'SOPClass')
exports.RTBrachyTreatmentRecordStorage = _make_uid('1.2.840.10008.5.1.4.1.1.481.6', 'RTBrachyTreatmentRecordStorage', 'SOPClass')
exports.RTTreatmentSummaryRecordStorage = _make_uid('1.2.840.10008.5.1.4.1.1.481.7', 'RTTreatmentSummaryRecordStorage', 'SOPClass')
exports.RTIonPlanStorage = _make_uid('1.2.840.10008.5.1.4.1.1.481.8', 'RTIonPlanStorage', 'SOPClass')
exports.RTIonBeamsTreatmentRecordStorage = _make_uid('1.2.840.10008.5.1.4.1.1.481.9', 'RTIonBeamsTreatmentRecordStorage', 'SOPClass')
exports.DICOSCTImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.501.1', 'DICOSCTImageStorage', 'SOPClass')
exports.DICOSDigitalXRayImageStorageForPresentation = _make_uid('1.2.840.10008.5.1.4.1.1.501.2.1', 'DICOSDigitalXRayImageStorageForPresentation', 'SOPClass')
exports.DICOSDigitalXRayImageStorageForProcessing = _make_uid('1.2.840.10008.5.1.4.1.1.501.2.2', 'DICOSDigitalXRayImageStorageForProcessing', 'SOPClass')
exports.DICOSThreatDetectionReportStorage = _make_uid('1.2.840.10008.5.1.4.1.1.501.3', 'DICOSThreatDetectionReportStorage', 'SOPClass')
exports.DICOS2DAITStorage = _make_uid('1.2.840.10008.5.1.4.1.1.501.4', 'DICOS2DAITStorage', 'SOPClass')
exports.DICOS3DAITStorage = _make_uid('1.2.840.10008.5.1.4.1.1.501.5', 'DICOS3DAITStorage', 'SOPClass')
exports.DICOSQuadrupoleResonanceQRStorage = _make_uid('1.2.840.10008.5.1.4.1.1.501.6', 'DICOSQuadrupoleResonanceQRStorage', 'SOPClass')
exports.EddyCurrentImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.601.1', 'EddyCurrentImageStorage', 'SOPClass')
exports.EddyCurrentMultiFrameImageStorage = _make_uid('1.2.840.10008.5.1.4.1.1.601.2', 'EddyCurrentMultiFrameImageStorage', 'SOPClass')
exports.PatientRootQueryRetrieveInformationModelFIND = _make_uid('1.2.840.10008.5.1.4.1.2.1.1', 'PatientRootQueryRetrieveInformationModelFIND', 'SOPClass')
exports.PatientRootQueryRetrieveInformationModelMOVE = _make_uid('1.2.840.10008.5.1.4.1.2.1.2', 'PatientRootQueryRetrieveInformationModelMOVE', 'SOPClass')
exports.PatientRootQueryRetrieveInformationModelGET = _make_uid('1.2.840.10008.5.1.4.1.2.1.3', 'PatientRootQueryRetrieveInformationModelGET', 'SOPClass')
exports.StudyRootQueryRetrieveInformationModelFIND = _make_uid('1.2.840.10008.5.1.4.1.2.2.1', 'StudyRootQueryRetrieveInformationModelFIND', 'SOPClass')
exports.StudyRootQueryRetrieveInformationModelMOVE = _make_uid('1.2.840.10008.5.1.4.1.2.2.2', 'StudyRootQueryRetrieveInformationModelMOVE', 'SOPClass')
exports.StudyRootQueryRetrieveInformationModelGET = _make_uid('1.2.840.10008.5.1.4.1.2.2.3', 'StudyRootQueryRetrieveInformationModelGET', 'SOPClass')
exports.PatientStudyOnlyQueryRetrieveInformationModelFINDRetired = _make_uid('1.2.840.10008.5.1.4.1.2.3.1', 'PatientStudyOnlyQueryRetrieveInformationModelFINDRetired', 'SOPClass')
exports.PatientStudyOnlyQueryRetrieveInformationModelMOVERetired = _make_uid('1.2.840.10008.5.1.4.1.2.3.2', 'PatientStudyOnlyQueryRetrieveInformationModelMOVERetired', 'SOPClass')
exports.PatientStudyOnlyQueryRetrieveInformationModelGETRetired = _make_uid('1.2.840.10008.5.1.4.1.2.3.3', 'PatientStudyOnlyQueryRetrieveInformationModelGETRetired', 'SOPClass')
exports.CompositeInstanceRootRetrieveMOVE = _make_uid('1.2.840.10008.5.1.4.1.2.4.2', 'CompositeInstanceRootRetrieveMOVE', 'SOPClass')
exports.CompositeInstanceRootRetrieveGET = _make_uid('1.2.840.10008.5.1.4.1.2.4.3', 'CompositeInstanceRootRetrieveGET', 'SOPClass')
exports.CompositeInstanceRetrieveWithoutBulkDataGET = _make_uid('1.2.840.10008.5.1.4.1.2.5.3', 'CompositeInstanceRetrieveWithoutBulkDataGET', 'SOPClass')
exports.ModalityWorklistInformationModelFIND = _make_uid('1.2.840.10008.5.1.4.31', 'ModalityWorklistInformationModelFIND', 'SOPClass')
exports.GeneralPurposeWorklistManagementMetaSOPClassRetired = _make_uid('1.2.840.10008.5.1.4.32', 'GeneralPurposeWorklistManagementMetaSOPClassRetired', 'MetaSOPClass')
exports.GeneralPurposeWorklistInformationModelFINDRetired = _make_uid('1.2.840.10008.5.1.4.32.1', 'GeneralPurposeWorklistInformationModelFINDRetired', 'SOPClass')
exports.GeneralPurposeScheduledProcedureStepSOPClassRetired = _make_uid('1.2.840.10008.5.1.4.32.2', 'GeneralPurposeScheduledProcedureStepSOPClassRetired', 'SOPClass')
exports.GeneralPurposePerformedProcedureStepSOPClassRetired = _make_uid('1.2.840.10008.5.1.4.32.3', 'GeneralPurposePerformedProcedureStepSOPClassRetired', 'SOPClass')
exports.InstanceAvailabilityNotificationSOPClass = _make_uid('1.2.840.10008.5.1.4.33', 'InstanceAvailabilityNotificationSOPClass', 'SOPClass')
exports.RTBeamsDeliveryInstructionStorageTrialRetired = _make_uid('1.2.840.10008.5.1.4.34.1', 'RTBeamsDeliveryInstructionStorageTrialRetired', 'SOPClass')
exports.RTConventionalMachineVerificationTrialRetired = _make_uid('1.2.840.10008.5.1.4.34.2', 'RTConventionalMachineVerificationTrialRetired', 'SOPClass')
exports.RTIonMachineVerificationTrialRetired = _make_uid('1.2.840.10008.5.1.4.34.3', 'RTIonMachineVerificationTrialRetired', 'SOPClass')
exports.UnifiedWorklistAndProcedureStepServiceClassTrialRetired = _make_uid('1.2.840.10008.5.1.4.34.4', 'UnifiedWorklistAndProcedureStepServiceClassTrialRetired', 'ServiceClass')
exports.UnifiedProcedureStepPushSOPClassTrialRetired = _make_uid('1.2.840.10008.5.1.4.34.4.1', 'UnifiedProcedureStepPushSOPClassTrialRetired', 'SOPClass')
exports.UnifiedProcedureStepWatchSOPClassTrialRetired = _make_uid('1.2.840.10008.5.1.4.34.4.2', 'UnifiedProcedureStepWatchSOPClassTrialRetired', 'SOPClass')
exports.UnifiedProcedureStepPullSOPClassTrialRetired = _make_uid('1.2.840.10008.5.1.4.34.4.3', 'UnifiedProcedureStepPullSOPClassTrialRetired', 'SOPClass')
exports.UnifiedProcedureStepEventSOPClassTrialRetired = _make_uid('1.2.840.10008.5.1.4.34.4.4', 'UnifiedProcedureStepEventSOPClassTrialRetired', 'SOPClass')
exports.UnifiedWorklistAndProcedureStepSOPInstance = _make_uid('1.2.840.10008.5.1.4.34.5', 'UnifiedWorklistAndProcedureStepSOPInstance', 'WellKnownSOPInstance')
exports.UnifiedWorklistAndProcedureStepServiceClass = _make_uid('1.2.840.10008.5.1.4.34.6', 'UnifiedWorklistAndProcedureStepServiceClass', 'ServiceClass')
exports.UnifiedProcedureStepPushSOPClass = _make_uid('1.2.840.10008.5.1.4.34.6.1', 'UnifiedProcedureStepPushSOPClass', 'SOPClass')
exports.UnifiedProcedureStepWatchSOPClass = _make_uid('1.2.840.10008.5.1.4.34.6.2', 'UnifiedProcedureStepWatchSOPClass', 'SOPClass')
exports.UnifiedProcedureStepPullSOPClass = _make_uid('1.2.840.10008.5.1.4.34.6.3', 'UnifiedProcedureStepPullSOPClass', 'SOPClass')
exports.UnifiedProcedureStepEventSOPClass = _make_uid('1.2.840.10008.5.1.4.34.6.4', 'UnifiedProcedureStepEventSOPClass', 'SOPClass')
exports.RTBeamsDeliveryInstructionStorage = _make_uid('1.2.840.10008.5.1.4.34.7', 'RTBeamsDeliveryInstructionStorage', 'SOPClass')
exports.RTConventionalMachineVerification = _make_uid('1.2.840.10008.5.1.4.34.8', 'RTConventionalMachineVerification', 'SOPClass')
exports.RTIonMachineVerification = _make_uid('1.2.840.10008.5.1.4.34.9', 'RTIonMachineVerification', 'SOPClass')
exports.GeneralRelevantPatientInformationQuery = _make_uid('1.2.840.10008.5.1.4.37.1', 'GeneralRelevantPatientInformationQuery', 'SOPClass')
exports.BreastImagingRelevantPatientInformationQuery = _make_uid('1.2.840.10008.5.1.4.37.2', 'BreastImagingRelevantPatientInformationQuery', 'SOPClass')
exports.CardiacRelevantPatientInformationQuery = _make_uid('1.2.840.10008.5.1.4.37.3', 'CardiacRelevantPatientInformationQuery', 'SOPClass')
exports.HangingProtocolStorage = _make_uid('1.2.840.10008.5.1.4.38.1', 'HangingProtocolStorage', 'SOPClass')
exports.HangingProtocolInformationModelFIND = _make_uid('1.2.840.10008.5.1.4.38.2', 'HangingProtocolInformationModelFIND', 'SOPClass')
exports.HangingProtocolInformationModelMOVE = _make_uid('1.2.840.10008.5.1.4.38.3', 'HangingProtocolInformationModelMOVE', 'SOPClass')
exports.HangingProtocolInformationModelGET = _make_uid('1.2.840.10008.5.1.4.38.4', 'HangingProtocolInformationModelGET', 'SOPClass')
exports.ColorPaletteStorage = _make_uid('1.2.840.10008.5.1.4.39.1', 'ColorPaletteStorage', 'Transfer')
exports.ColorPaletteInformationModelFIND = _make_uid('1.2.840.10008.5.1.4.39.2', 'ColorPaletteInformationModelFIND', 'QueryRetrieve')
exports.ColorPaletteInformationModelMOVE = _make_uid('1.2.840.10008.5.1.4.39.3', 'ColorPaletteInformationModelMOVE', 'QueryRetrieve')
exports.ColorPaletteInformationModelGET = _make_uid('1.2.840.10008.5.1.4.39.4', 'ColorPaletteInformationModelGET', 'QueryRetrieve')
exports.ProductCharacteristicsQuerySOPClass = _make_uid('1.2.840.10008.5.1.4.41', 'ProductCharacteristicsQuerySOPClass', 'SOPClass')
exports.SubstanceApprovalQuerySOPClass = _make_uid('1.2.840.10008.5.1.4.42', 'SubstanceApprovalQuerySOPClass', 'SOPClass')
exports.GenericImplantTemplateStorage = _make_uid('1.2.840.10008.5.1.4.43.1', 'GenericImplantTemplateStorage', 'SOPClass')
exports.GenericImplantTemplateInformationModelFIND = _make_uid('1.2.840.10008.5.1.4.43.2', 'GenericImplantTemplateInformationModelFIND', 'SOPClass')
exports.GenericImplantTemplateInformationModelMOVE = _make_uid('1.2.840.10008.5.1.4.43.3', 'GenericImplantTemplateInformationModelMOVE', 'SOPClass')
exports.GenericImplantTemplateInformationModelGET = _make_uid('1.2.840.10008.5.1.4.43.4', 'GenericImplantTemplateInformationModelGET', 'SOPClass')
exports.ImplantAssemblyTemplateStorage = _make_uid('1.2.840.10008.5.1.4.44.1', 'ImplantAssemblyTemplateStorage', 'SOPClass')
exports.ImplantAssemblyTemplateInformationModelFIND = _make_uid('1.2.840.10008.5.1.4.44.2', 'ImplantAssemblyTemplateInformationModelFIND', 'SOPClass')
exports.ImplantAssemblyTemplateInformationModelMOVE = _make_uid('1.2.840.10008.5.1.4.44.3', 'ImplantAssemblyTemplateInformationModelMOVE', 'SOPClass')
exports.ImplantAssemblyTemplateInformationModelGET = _make_uid('1.2.840.10008.5.1.4.44.4', 'ImplantAssemblyTemplateInformationModelGET', 'SOPClass')
exports.ImplantTemplateGroupStorage = _make_uid('1.2.840.10008.5.1.4.45.1', 'ImplantTemplateGroupStorage', 'SOPClass')
exports.ImplantTemplateGroupInformationModelFIND = _make_uid('1.2.840.10008.5.1.4.45.2', 'ImplantTemplateGroupInformationModelFIND', 'SOPClass')
exports.ImplantTemplateGroupInformationModelMOVE = _make_uid('1.2.840.10008.5.1.4.45.3', 'ImplantTemplateGroupInformationModelMOVE', 'SOPClass')
exports.ImplantTemplateGroupInformationModelGET = _make_uid('1.2.840.10008.5.1.4.45.4', 'ImplantTemplateGroupInformationModelGET', 'SOPClass')
exports.NativeDICOMModel = _make_uid('1.2.840.10008.7.1.1', 'NativeDICOMModel', 'ApplicationHostingModel')
exports.AbstractMultiDimensionalImageModel = _make_uid('1.2.840.10008.7.1.2', 'AbstractMultiDimensionalImageModel', 'ApplicationHostingModel')
exports.dicomDeviceName = _make_uid('1.2.840.10008.15.0.3.1', 'dicomDeviceName', 'LDAPOID')
exports.dicomDescription = _make_uid('1.2.840.10008.15.0.3.2', 'dicomDescription', 'LDAPOID')
exports.dicomManufacturer = _make_uid('1.2.840.10008.15.0.3.3', 'dicomManufacturer', 'LDAPOID')
exports.dicomManufacturerModelName = _make_uid('1.2.840.10008.15.0.3.4', 'dicomManufacturerModelName', 'LDAPOID')
exports.dicomSoftwareVersion = _make_uid('1.2.840.10008.15.0.3.5', 'dicomSoftwareVersion', 'LDAPOID')
exports.dicomVendorData = _make_uid('1.2.840.10008.15.0.3.6', 'dicomVendorData', 'LDAPOID')
exports.dicomAETitle = _make_uid('1.2.840.10008.15.0.3.7', 'dicomAETitle', 'LDAPOID')
exports.dicomNetworkConnectionReference = _make_uid('1.2.840.10008.15.0.3.8', 'dicomNetworkConnectionReference', 'LDAPOID')
exports.dicomApplicationCluster = _make_uid('1.2.840.10008.15.0.3.9', 'dicomApplicationCluster', 'LDAPOID')
exports.dicomAssociationInitiator = _make_uid('1.2.840.10008.15.0.3.10', 'dicomAssociationInitiator', 'LDAPOID')
exports.dicomAssociationAcceptor = _make_uid('1.2.840.10008.15.0.3.11', 'dicomAssociationAcceptor', 'LDAPOID')
exports.dicomHostname = _make_uid('1.2.840.10008.15.0.3.12', 'dicomHostname', 'LDAPOID')
exports.dicomPort = _make_uid('1.2.840.10008.15.0.3.13', 'dicomPort', 'LDAPOID')
exports.dicomSOPClass = _make_uid('1.2.840.10008.15.0.3.14', 'dicomSOPClass', 'LDAPOID')
exports.dicomTransferRole = _make_uid('1.2.840.10008.15.0.3.15', 'dicomTransferRole', 'LDAPOID')
exports.dicomTransferSyntax = _make_uid('1.2.840.10008.15.0.3.16', 'dicomTransferSyntax', 'LDAPOID')
exports.dicomPrimaryDeviceType = _make_uid('1.2.840.10008.15.0.3.17', 'dicomPrimaryDeviceType', 'LDAPOID')
exports.dicomRelatedDeviceReference = _make_uid('1.2.840.10008.15.0.3.18', 'dicomRelatedDeviceReference', 'LDAPOID')
exports.dicomPreferredCalledAETitle = _make_uid('1.2.840.10008.15.0.3.19', 'dicomPreferredCalledAETitle', 'LDAPOID')
exports.dicomTLSCyphersuite = _make_uid('1.2.840.10008.15.0.3.20', 'dicomTLSCyphersuite', 'LDAPOID')
exports.dicomAuthorizedNodeCertificateReference = _make_uid('1.2.840.10008.15.0.3.21', 'dicomAuthorizedNodeCertificateReference', 'LDAPOID')
exports.dicomThisNodeCertificateReference = _make_uid('1.2.840.10008.15.0.3.22', 'dicomThisNodeCertificateReference', 'LDAPOID')
exports.dicomInstalled = _make_uid('1.2.840.10008.15.0.3.23', 'dicomInstalled', 'LDAPOID')
exports.dicomStationName = _make_uid('1.2.840.10008.15.0.3.24', 'dicomStationName', 'LDAPOID')
exports.dicomDeviceSerialNumber = _make_uid('1.2.840.10008.15.0.3.25', 'dicomDeviceSerialNumber', 'LDAPOID')
exports.dicomInstitutionName = _make_uid('1.2.840.10008.15.0.3.26', 'dicomInstitutionName', 'LDAPOID')
exports.dicomInstitutionAddress = _make_uid('1.2.840.10008.15.0.3.27', 'dicomInstitutionAddress', 'LDAPOID')
exports.dicomInstitutionDepartmentName = _make_uid('1.2.840.10008.15.0.3.28', 'dicomInstitutionDepartmentName', 'LDAPOID')
exports.dicomIssuerOfPatientID = _make_uid('1.2.840.10008.15.0.3.29', 'dicomIssuerOfPatientID', 'LDAPOID')
exports.dicomPreferredCallingAETitle = _make_uid('1.2.840.10008.15.0.3.30', 'dicomPreferredCallingAETitle', 'LDAPOID')
exports.dicomSupportedCharacterSet = _make_uid('1.2.840.10008.15.0.3.31', 'dicomSupportedCharacterSet', 'LDAPOID')
exports.dicomConfigurationRoot = _make_uid('1.2.840.10008.15.0.4.1', 'dicomConfigurationRoot', 'LDAPOID')
exports.dicomDevicesRoot = _make_uid('1.2.840.10008.15.0.4.2', 'dicomDevicesRoot', 'LDAPOID')
exports.dicomUniqueAETitlesRegistryRoot = _make_uid('1.2.840.10008.15.0.4.3', 'dicomUniqueAETitlesRegistryRoot', 'LDAPOID')
exports.dicomDevice = _make_uid('1.2.840.10008.15.0.4.4', 'dicomDevice', 'LDAPOID')
exports.dicomNetworkAE = _make_uid('1.2.840.10008.15.0.4.5', 'dicomNetworkAE', 'LDAPOID')
exports.dicomNetworkConnection = _make_uid('1.2.840.10008.15.0.4.6', 'dicomNetworkConnection', 'LDAPOID')
exports.dicomUniqueAETitle = _make_uid('1.2.840.10008.15.0.4.7', 'dicomUniqueAETitle', 'LDAPOID')
exports.dicomTransferCapability = _make_uid('1.2.840.10008.15.0.4.8', 'dicomTransferCapability', 'LDAPOID')
exports.UniversalCoordinatedTime = _make_uid('1.2.840.10008.15.1.1', 'UniversalCoordinatedTime', 'SynchronizationFrameOfReference')
_UID_DICT =
  '1.2.840.10008.1.1': exports.VerificationSOPClass,
  '1.2.840.10008.1.2': exports.ImplicitVRLittleEndian,
  '1.2.840.10008.1.2.1': exports.ExplicitVRLittleEndian,
  '1.2.840.10008.1.2.1.99': exports.DeflatedExplicitVRLittleEndian,
  '1.2.840.10008.1.2.2': exports.ExplicitVRBigEndianRetired,
  '1.2.840.10008.1.2.4.50': exports.JPEGBaseline1,
  '1.2.840.10008.1.2.4.51': exports.JPEGExtended24,
  '1.2.840.10008.1.2.4.52': exports.JPEGExtended35Retired,
  '1.2.840.10008.1.2.4.53': exports.JPEGSpectralSelectionNonHierarchical68Retired,
  '1.2.840.10008.1.2.4.54': exports.JPEGSpectralSelectionNonHierarchical79Retired,
  '1.2.840.10008.1.2.4.55': exports.JPEGFullProgressionNonHierarchical1012Retired,
  '1.2.840.10008.1.2.4.56': exports.JPEGFullProgressionNonHierarchical1113Retired,
  '1.2.840.10008.1.2.4.57': exports.JPEGLosslessNonHierarchical14,
  '1.2.840.10008.1.2.4.58': exports.JPEGLosslessNonHierarchical15Retired,
  '1.2.840.10008.1.2.4.59': exports.JPEGExtendedHierarchical1618Retired,
  '1.2.840.10008.1.2.4.60': exports.JPEGExtendedHierarchical1719Retired,
  '1.2.840.10008.1.2.4.61': exports.JPEGSpectralSelectionHierarchical2022Retired,
  '1.2.840.10008.1.2.4.62': exports.JPEGSpectralSelectionHierarchical2123Retired,
  '1.2.840.10008.1.2.4.63': exports.JPEGFullProgressionHierarchical2426Retired,
  '1.2.840.10008.1.2.4.64': exports.JPEGFullProgressionHierarchical2527Retired,
  '1.2.840.10008.1.2.4.65': exports.JPEGLosslessHierarchical28Retired,
  '1.2.840.10008.1.2.4.66': exports.JPEGLosslessHierarchical29Retired,
  '1.2.840.10008.1.2.4.70': exports.JPEGLossless,
  '1.2.840.10008.1.2.4.80': exports.JPEGLSLossless,
  '1.2.840.10008.1.2.4.81': exports.JPEGLSLossyNearLossless,
  '1.2.840.10008.1.2.4.90': exports.JPEG2000LosslessOnly,
  '1.2.840.10008.1.2.4.91': exports.JPEG2000,
  '1.2.840.10008.1.2.4.92': exports.JPEG2000Part2MultiComponentLosslessOnly,
  '1.2.840.10008.1.2.4.93': exports.JPEG2000Part2MultiComponent,
  '1.2.840.10008.1.2.4.94': exports.JPIPReferenced,
  '1.2.840.10008.1.2.4.95': exports.JPIPReferencedDeflate,
  '1.2.840.10008.1.2.4.100': exports.MPEG2,
  '1.2.840.10008.1.2.4.101': exports.MPEG2MainProfileHighLevel,
  '1.2.840.10008.1.2.4.102': exports.MPEG4AVCH264HighProfileLevel41,
  '1.2.840.10008.1.2.4.103': exports.MPEG4AVCH264BDCompatibleHighProfileLevel41,
  '1.2.840.10008.1.2.5': exports.RLELossless,
  '1.2.840.10008.1.2.6.1': exports.RFC2557MIMEEncapsulation,
  '1.2.840.10008.1.2.6.2': exports.XMLEncoding,
  '1.2.840.10008.1.3.10': exports.MediaStorageDirectoryStorage,
  '1.2.840.10008.1.4.1.1': exports.TalairachBrainAtlasFrameOfReference,
  '1.2.840.10008.1.4.1.2': exports.SPM2T1FrameOfReference,
  '1.2.840.10008.1.4.1.3': exports.SPM2T2FrameOfReference,
  '1.2.840.10008.1.4.1.4': exports.SPM2PDFrameOfReference,
  '1.2.840.10008.1.4.1.5': exports.SPM2EPIFrameOfReference,
  '1.2.840.10008.1.4.1.6': exports.SPM2FILT1FrameOfReference,
  '1.2.840.10008.1.4.1.7': exports.SPM2PETFrameOfReference,
  '1.2.840.10008.1.4.1.8': exports.SPM2TRANSMFrameOfReference,
  '1.2.840.10008.1.4.1.9': exports.SPM2SPECTFrameOfReference,
  '1.2.840.10008.1.4.1.10': exports.SPM2GRAYFrameOfReference,
  '1.2.840.10008.1.4.1.11': exports.SPM2WHITEFrameOfReference,
  '1.2.840.10008.1.4.1.12': exports.SPM2CSFFrameOfReference,
  '1.2.840.10008.1.4.1.13': exports.SPM2BRAINMASKFrameOfReference,
  '1.2.840.10008.1.4.1.14': exports.SPM2AVG305T1FrameOfReference,
  '1.2.840.10008.1.4.1.15': exports.SPM2AVG152T1FrameOfReference,
  '1.2.840.10008.1.4.1.16': exports.SPM2AVG152T2FrameOfReference,
  '1.2.840.10008.1.4.1.17': exports.SPM2AVG152PDFrameOfReference,
  '1.2.840.10008.1.4.1.18': exports.SPM2SINGLESUBJT1FrameOfReference,
  '1.2.840.10008.1.4.2.1': exports.ICBM452T1FrameOfReference,
  '1.2.840.10008.1.4.2.2': exports.ICBMSingleSubjectMRIFrameOfReference,
  '1.2.840.10008.1.5.1': exports.HotIronColorPaletteSOPInstance,
  '1.2.840.10008.1.5.2': exports.PETColorPaletteSOPInstance,
  '1.2.840.10008.1.5.3': exports.HotMetalBlueColorPaletteSOPInstance,
  '1.2.840.10008.1.5.4': exports.PET20StepColorPaletteSOPInstance,
  '1.2.840.10008.1.9': exports.BasicStudyContentNotificationSOPClassRetired,
  '1.2.840.10008.1.20.1': exports.StorageCommitmentPushModelSOPClass,
  '1.2.840.10008.1.20.1.1': exports.StorageCommitmentPushModelSOPInstance,
  '1.2.840.10008.1.20.2': exports.StorageCommitmentPullModelSOPClassRetired,
  '1.2.840.10008.1.20.2.1': exports.StorageCommitmentPullModelSOPInstanceRetired,
  '1.2.840.10008.1.40': exports.ProceduralEventLoggingSOPClass,
  '1.2.840.10008.1.40.1': exports.ProceduralEventLoggingSOPInstance,
  '1.2.840.10008.1.42': exports.SubstanceAdministrationLoggingSOPClass,
  '1.2.840.10008.1.42.1': exports.SubstanceAdministrationLoggingSOPInstance,
  '1.2.840.10008.2.6.1': exports.DICOMUIDRegistry,
  '1.2.840.10008.2.16.4': exports.DICOMControlledTerminology,
  '1.2.840.10008.3.1.1.1': exports.DICOMApplicationContextName,
  '1.2.840.10008.3.1.2.1.1': exports.DetachedPatientManagementSOPClassRetired,
  '1.2.840.10008.3.1.2.1.4': exports.DetachedPatientManagementMetaSOPClassRetired,
  '1.2.840.10008.3.1.2.2.1': exports.DetachedVisitManagementSOPClassRetired,
  '1.2.840.10008.3.1.2.3.1': exports.DetachedStudyManagementSOPClassRetired,
  '1.2.840.10008.3.1.2.3.2': exports.StudyComponentManagementSOPClassRetired,
  '1.2.840.10008.3.1.2.3.3': exports.ModalityPerformedProcedureStepSOPClass,
  '1.2.840.10008.3.1.2.3.4': exports.ModalityPerformedProcedureStepRetrieveSOPClass,
  '1.2.840.10008.3.1.2.3.5': exports.ModalityPerformedProcedureStepNotificationSOPClass,
  '1.2.840.10008.3.1.2.5.1': exports.DetachedResultsManagementSOPClassRetired,
  '1.2.840.10008.3.1.2.5.4': exports.DetachedResultsManagementMetaSOPClassRetired,
  '1.2.840.10008.3.1.2.5.5': exports.DetachedStudyManagementMetaSOPClassRetired,
  '1.2.840.10008.3.1.2.6.1': exports.DetachedInterpretationManagementSOPClassRetired,
  '1.2.840.10008.4.2': exports.StorageServiceClass,
  '1.2.840.10008.5.1.1.1': exports.BasicFilmSessionSOPClass,
  '1.2.840.10008.5.1.1.2': exports.BasicFilmBoxSOPClass,
  '1.2.840.10008.5.1.1.4': exports.BasicGrayscaleImageBoxSOPClass,
  '1.2.840.10008.5.1.1.4.1': exports.BasicColorImageBoxSOPClass,
  '1.2.840.10008.5.1.1.4.2': exports.ReferencedImageBoxSOPClassRetired,
  '1.2.840.10008.5.1.1.9': exports.BasicGrayscalePrintManagementMetaSOPClass,
  '1.2.840.10008.5.1.1.9.1': exports.ReferencedGrayscalePrintManagementMetaSOPClassRetired,
  '1.2.840.10008.5.1.1.14': exports.PrintJobSOPClass,
  '1.2.840.10008.5.1.1.15': exports.BasicAnnotationBoxSOPClass,
  '1.2.840.10008.5.1.1.16': exports.PrinterSOPClass,
  '1.2.840.10008.5.1.1.16.376': exports.PrinterConfigurationRetrievalSOPClass,
  '1.2.840.10008.5.1.1.17': exports.PrinterSOPInstance,
  '1.2.840.10008.5.1.1.17.376': exports.PrinterConfigurationRetrievalSOPInstance,
  '1.2.840.10008.5.1.1.18': exports.BasicColorPrintManagementMetaSOPClass,
  '1.2.840.10008.5.1.1.18.1': exports.ReferencedColorPrintManagementMetaSOPClassRetired,
  '1.2.840.10008.5.1.1.22': exports.VOILUTBoxSOPClass,
  '1.2.840.10008.5.1.1.23': exports.PresentationLUTSOPClass,
  '1.2.840.10008.5.1.1.24': exports.ImageOverlayBoxSOPClassRetired,
  '1.2.840.10008.5.1.1.24.1': exports.BasicPrintImageOverlayBoxSOPClassRetired,
  '1.2.840.10008.5.1.1.25': exports.PrintQueueSOPInstanceRetired,
  '1.2.840.10008.5.1.1.26': exports.PrintQueueManagementSOPClassRetired,
  '1.2.840.10008.5.1.1.27': exports.StoredPrintStorageSOPClassRetired,
  '1.2.840.10008.5.1.1.29': exports.HardcopyGrayscaleImageStorageSOPClassRetired,
  '1.2.840.10008.5.1.1.30': exports.HardcopyColorImageStorageSOPClassRetired,
  '1.2.840.10008.5.1.1.31': exports.PullPrintRequestSOPClassRetired,
  '1.2.840.10008.5.1.1.32': exports.PullStoredPrintManagementMetaSOPClassRetired,
  '1.2.840.10008.5.1.1.33': exports.MediaCreationManagementSOPClassUID,
  '1.2.840.10008.5.1.1.40': exports.DisplaySystemSOPClass,
  '1.2.840.10008.5.1.1.40.1': exports.DisplaySystemSOPInstance,
  '1.2.840.10008.5.1.4.1.1.1': exports.ComputedRadiographyImageStorage,
  '1.2.840.10008.5.1.4.1.1.1.1': exports.DigitalXRayImageStorageForPresentation,
  '1.2.840.10008.5.1.4.1.1.1.1.1': exports.DigitalXRayImageStorageForProcessing,
  '1.2.840.10008.5.1.4.1.1.1.2': exports.DigitalMammographyXRayImageStorageForPresentation,
  '1.2.840.10008.5.1.4.1.1.1.2.1': exports.DigitalMammographyXRayImageStorageForProcessing,
  '1.2.840.10008.5.1.4.1.1.1.3': exports.DigitalIntraOralXRayImageStorageForPresentation,
  '1.2.840.10008.5.1.4.1.1.1.3.1': exports.DigitalIntraOralXRayImageStorageForProcessing,
  '1.2.840.10008.5.1.4.1.1.2': exports.CTImageStorage,
  '1.2.840.10008.5.1.4.1.1.2.1': exports.EnhancedCTImageStorage,
  '1.2.840.10008.5.1.4.1.1.2.2': exports.LegacyConvertedEnhancedCTImageStorage,
  '1.2.840.10008.5.1.4.1.1.3': exports.UltrasoundMultiFrameImageStorageRetired,
  '1.2.840.10008.5.1.4.1.1.3.1': exports.UltrasoundMultiFrameImageStorage,
  '1.2.840.10008.5.1.4.1.1.4': exports.MRImageStorage,
  '1.2.840.10008.5.1.4.1.1.4.1': exports.EnhancedMRImageStorage,
  '1.2.840.10008.5.1.4.1.1.4.2': exports.MRSpectroscopyStorage,
  '1.2.840.10008.5.1.4.1.1.4.3': exports.EnhancedMRColorImageStorage,
  '1.2.840.10008.5.1.4.1.1.4.4': exports.LegacyConvertedEnhancedMRImageStorage,
  '1.2.840.10008.5.1.4.1.1.5': exports.NuclearMedicineImageStorageRetired,
  '1.2.840.10008.5.1.4.1.1.6': exports.UltrasoundImageStorageRetired,
  '1.2.840.10008.5.1.4.1.1.6.1': exports.UltrasoundImageStorage,
  '1.2.840.10008.5.1.4.1.1.6.2': exports.EnhancedUSVolumeStorage,
  '1.2.840.10008.5.1.4.1.1.7': exports.SecondaryCaptureImageStorage,
  '1.2.840.10008.5.1.4.1.1.7.1': exports.MultiFrameSingleBitSecondaryCaptureImageStorage,
  '1.2.840.10008.5.1.4.1.1.7.2': exports.MultiFrameGrayscaleByteSecondaryCaptureImageStorage,
  '1.2.840.10008.5.1.4.1.1.7.3': exports.MultiFrameGrayscaleWordSecondaryCaptureImageStorage,
  '1.2.840.10008.5.1.4.1.1.7.4': exports.MultiFrameTrueColorSecondaryCaptureImageStorage,
  '1.2.840.10008.5.1.4.1.1.8': exports.StandaloneOverlayStorageRetired,
  '1.2.840.10008.5.1.4.1.1.9': exports.StandaloneCurveStorageRetired,
  '1.2.840.10008.5.1.4.1.1.9.1': exports.WaveformStorageTrialRetired,
  '1.2.840.10008.5.1.4.1.1.9.1.1': exports.TwelveLeadECGWaveformStorage,
  '1.2.840.10008.5.1.4.1.1.9.1.2': exports.GeneralECGWaveformStorage,
  '1.2.840.10008.5.1.4.1.1.9.1.3': exports.AmbulatoryECGWaveformStorage,
  '1.2.840.10008.5.1.4.1.1.9.2.1': exports.HemodynamicWaveformStorage,
  '1.2.840.10008.5.1.4.1.1.9.3.1': exports.CardiacElectrophysiologyWaveformStorage,
  '1.2.840.10008.5.1.4.1.1.9.4.1': exports.BasicVoiceAudioWaveformStorage,
  '1.2.840.10008.5.1.4.1.1.9.4.2': exports.GeneralAudioWaveformStorage,
  '1.2.840.10008.5.1.4.1.1.9.5.1': exports.ArterialPulseWaveformStorage,
  '1.2.840.10008.5.1.4.1.1.9.6.1': exports.RespiratoryWaveformStorage,
  '1.2.840.10008.5.1.4.1.1.10': exports.StandaloneModalityLUTStorageRetired,
  '1.2.840.10008.5.1.4.1.1.11': exports.StandaloneVOILUTStorageRetired,
  '1.2.840.10008.5.1.4.1.1.11.1': exports.GrayscaleSoftcopyPresentationStateStorageSOPClass,
  '1.2.840.10008.5.1.4.1.1.11.2': exports.ColorSoftcopyPresentationStateStorageSOPClass,
  '1.2.840.10008.5.1.4.1.1.11.3': exports.PseudoColorSoftcopyPresentationStateStorageSOPClass,
  '1.2.840.10008.5.1.4.1.1.11.4': exports.BlendingSoftcopyPresentationStateStorageSOPClass,
  '1.2.840.10008.5.1.4.1.1.11.5': exports.XAXRFGrayscaleSoftcopyPresentationStateStorage,
  '1.2.840.10008.5.1.4.1.1.12.1': exports.XRayAngiographicImageStorage,
  '1.2.840.10008.5.1.4.1.1.12.1.1': exports.EnhancedXAImageStorage,
  '1.2.840.10008.5.1.4.1.1.12.2': exports.XRayRadiofluoroscopicImageStorage,
  '1.2.840.10008.5.1.4.1.1.12.2.1': exports.EnhancedXRFImageStorage,
  '1.2.840.10008.5.1.4.1.1.12.3': exports.XRayAngiographicBiPlaneImageStorageRetired,
  '1.2.840.10008.5.1.4.1.1.13.1.1': exports.XRay3DAngiographicImageStorage,
  '1.2.840.10008.5.1.4.1.1.13.1.2': exports.XRay3DCraniofacialImageStorage,
  '1.2.840.10008.5.1.4.1.1.13.1.3': exports.BreastTomosynthesisImageStorage,
  '1.2.840.10008.5.1.4.1.1.13.1.4': exports.BreastProjectionXRayImageStorageForPresentation,
  '1.2.840.10008.5.1.4.1.1.13.1.5': exports.BreastProjectionXRayImageStorageForProcessing,
  '1.2.840.10008.5.1.4.1.1.14.1': exports.IntravascularOpticalCoherenceTomographyImageStorageForPresentation,
  '1.2.840.10008.5.1.4.1.1.14.2': exports.IntravascularOpticalCoherenceTomographyImageStorageForProcessing,
  '1.2.840.10008.5.1.4.1.1.20': exports.NuclearMedicineImageStorage,
  '1.2.840.10008.5.1.4.1.1.66': exports.RawDataStorage,
  '1.2.840.10008.5.1.4.1.1.66.1': exports.SpatialRegistrationStorage,
  '1.2.840.10008.5.1.4.1.1.66.2': exports.SpatialFiducialsStorage,
  '1.2.840.10008.5.1.4.1.1.66.3': exports.DeformableSpatialRegistrationStorage,
  '1.2.840.10008.5.1.4.1.1.66.4': exports.SegmentationStorage,
  '1.2.840.10008.5.1.4.1.1.66.5': exports.SurfaceSegmentationStorage,
  '1.2.840.10008.5.1.4.1.1.67': exports.RealWorldValueMappingStorage,
  '1.2.840.10008.5.1.4.1.1.68.1': exports.SurfaceScanMeshStorage,
  '1.2.840.10008.5.1.4.1.1.68.2': exports.SurfaceScanPointCloudStorage,
  '1.2.840.10008.5.1.4.1.1.77.1': exports.VLImageStorageTrialRetired,
  '1.2.840.10008.5.1.4.1.1.77.2': exports.VLMultiFrameImageStorageTrialRetired,
  '1.2.840.10008.5.1.4.1.1.77.1.1': exports.VLEndoscopicImageStorage,
  '1.2.840.10008.5.1.4.1.1.77.1.1.1': exports.VideoEndoscopicImageStorage,
  '1.2.840.10008.5.1.4.1.1.77.1.2': exports.VLMicroscopicImageStorage,
  '1.2.840.10008.5.1.4.1.1.77.1.2.1': exports.VideoMicroscopicImageStorage,
  '1.2.840.10008.5.1.4.1.1.77.1.3': exports.VLSlideCoordinatesMicroscopicImageStorage,
  '1.2.840.10008.5.1.4.1.1.77.1.4': exports.VLPhotographicImageStorage,
  '1.2.840.10008.5.1.4.1.1.77.1.4.1': exports.VideoPhotographicImageStorage,
  '1.2.840.10008.5.1.4.1.1.77.1.5.1': exports.OphthalmicPhotography8BitImageStorage,
  '1.2.840.10008.5.1.4.1.1.77.1.5.2': exports.OphthalmicPhotography16BitImageStorage,
  '1.2.840.10008.5.1.4.1.1.77.1.5.3': exports.StereometricRelationshipStorage,
  '1.2.840.10008.5.1.4.1.1.77.1.5.4': exports.OphthalmicTomographyImageStorage,
  '1.2.840.10008.5.1.4.1.1.77.1.6': exports.VLWholeSlideMicroscopyImageStorage,
  '1.2.840.10008.5.1.4.1.1.78.1': exports.LensometryMeasurementsStorage,
  '1.2.840.10008.5.1.4.1.1.78.2': exports.AutorefractionMeasurementsStorage,
  '1.2.840.10008.5.1.4.1.1.78.3': exports.KeratometryMeasurementsStorage,
  '1.2.840.10008.5.1.4.1.1.78.4': exports.SubjectiveRefractionMeasurementsStorage,
  '1.2.840.10008.5.1.4.1.1.78.5': exports.VisualAcuityMeasurementsStorage,
  '1.2.840.10008.5.1.4.1.1.78.6': exports.SpectaclePrescriptionReportStorage,
  '1.2.840.10008.5.1.4.1.1.78.7': exports.OphthalmicAxialMeasurementsStorage,
  '1.2.840.10008.5.1.4.1.1.78.8': exports.IntraocularLensCalculationsStorage,
  '1.2.840.10008.5.1.4.1.1.79.1': exports.MacularGridThicknessAndVolumeReportStorage,
  '1.2.840.10008.5.1.4.1.1.80.1': exports.OphthalmicVisualFieldStaticPerimetryMeasurementsStorage,
  '1.2.840.10008.5.1.4.1.1.81.1': exports.OphthalmicThicknessMapStorage,
  '1.2.840.10008.5.1.4.1.1.82.1': exports.CornealTopographyMapStorage,
  '1.2.840.10008.5.1.4.1.1.88.1': exports.TextSRStorageTrialRetired,
  '1.2.840.10008.5.1.4.1.1.88.2': exports.AudioSRStorageTrialRetired,
  '1.2.840.10008.5.1.4.1.1.88.3': exports.DetailSRStorageTrialRetired,
  '1.2.840.10008.5.1.4.1.1.88.4': exports.ComprehensiveSRStorageTrialRetired,
  '1.2.840.10008.5.1.4.1.1.88.11': exports.BasicTextSRStorage,
  '1.2.840.10008.5.1.4.1.1.88.22': exports.EnhancedSRStorage,
  '1.2.840.10008.5.1.4.1.1.88.33': exports.ComprehensiveSRStorage,
  '1.2.840.10008.5.1.4.1.1.88.34': exports.Comprehensive3DSRStorage,
  '1.2.840.10008.5.1.4.1.1.88.40': exports.ProcedureLogStorage,
  '1.2.840.10008.5.1.4.1.1.88.50': exports.MammographyCADSRStorage,
  '1.2.840.10008.5.1.4.1.1.88.59': exports.KeyObjectSelectionDocumentStorage,
  '1.2.840.10008.5.1.4.1.1.88.65': exports.ChestCADSRStorage,
  '1.2.840.10008.5.1.4.1.1.88.67': exports.XRayRadiationDoseSRStorage,
  '1.2.840.10008.5.1.4.1.1.88.68': exports.RadiopharmaceuticalRadiationDoseSRStorage,
  '1.2.840.10008.5.1.4.1.1.88.69': exports.ColonCADSRStorage,
  '1.2.840.10008.5.1.4.1.1.88.70': exports.ImplantationPlanSRStorage,
  '1.2.840.10008.5.1.4.1.1.104.1': exports.EncapsulatedPDFStorage,
  '1.2.840.10008.5.1.4.1.1.104.2': exports.EncapsulatedCDAStorage,
  '1.2.840.10008.5.1.4.1.1.128': exports.PositronEmissionTomographyImageStorage,
  '1.2.840.10008.5.1.4.1.1.128.1': exports.LegacyConvertedEnhancedPETImageStorage,
  '1.2.840.10008.5.1.4.1.1.129': exports.StandalonePETCurveStorageRetired,
  '1.2.840.10008.5.1.4.1.1.130': exports.EnhancedPETImageStorage,
  '1.2.840.10008.5.1.4.1.1.131': exports.BasicStructuredDisplayStorage,
  '1.2.840.10008.5.1.4.1.1.481.1': exports.RTImageStorage,
  '1.2.840.10008.5.1.4.1.1.481.2': exports.RTDoseStorage,
  '1.2.840.10008.5.1.4.1.1.481.3': exports.RTStructureSetStorage,
  '1.2.840.10008.5.1.4.1.1.481.4': exports.RTBeamsTreatmentRecordStorage,
  '1.2.840.10008.5.1.4.1.1.481.5': exports.RTPlanStorage,
  '1.2.840.10008.5.1.4.1.1.481.6': exports.RTBrachyTreatmentRecordStorage,
  '1.2.840.10008.5.1.4.1.1.481.7': exports.RTTreatmentSummaryRecordStorage,
  '1.2.840.10008.5.1.4.1.1.481.8': exports.RTIonPlanStorage,
  '1.2.840.10008.5.1.4.1.1.481.9': exports.RTIonBeamsTreatmentRecordStorage,
  '1.2.840.10008.5.1.4.1.1.501.1': exports.DICOSCTImageStorage,
  '1.2.840.10008.5.1.4.1.1.501.2.1': exports.DICOSDigitalXRayImageStorageForPresentation,
  '1.2.840.10008.5.1.4.1.1.501.2.2': exports.DICOSDigitalXRayImageStorageForProcessing,
  '1.2.840.10008.5.1.4.1.1.501.3': exports.DICOSThreatDetectionReportStorage,
  '1.2.840.10008.5.1.4.1.1.501.4': exports.DICOS2DAITStorage,
  '1.2.840.10008.5.1.4.1.1.501.5': exports.DICOS3DAITStorage,
  '1.2.840.10008.5.1.4.1.1.501.6': exports.DICOSQuadrupoleResonanceQRStorage,
  '1.2.840.10008.5.1.4.1.1.601.1': exports.EddyCurrentImageStorage,
  '1.2.840.10008.5.1.4.1.1.601.2': exports.EddyCurrentMultiFrameImageStorage,
  '1.2.840.10008.5.1.4.1.2.1.1': exports.PatientRootQueryRetrieveInformationModelFIND,
  '1.2.840.10008.5.1.4.1.2.1.2': exports.PatientRootQueryRetrieveInformationModelMOVE,
  '1.2.840.10008.5.1.4.1.2.1.3': exports.PatientRootQueryRetrieveInformationModelGET,
  '1.2.840.10008.5.1.4.1.2.2.1': exports.StudyRootQueryRetrieveInformationModelFIND,
  '1.2.840.10008.5.1.4.1.2.2.2': exports.StudyRootQueryRetrieveInformationModelMOVE,
  '1.2.840.10008.5.1.4.1.2.2.3': exports.StudyRootQueryRetrieveInformationModelGET,
  '1.2.840.10008.5.1.4.1.2.3.1': exports.PatientStudyOnlyQueryRetrieveInformationModelFINDRetired,
  '1.2.840.10008.5.1.4.1.2.3.2': exports.PatientStudyOnlyQueryRetrieveInformationModelMOVERetired,
  '1.2.840.10008.5.1.4.1.2.3.3': exports.PatientStudyOnlyQueryRetrieveInformationModelGETRetired,
  '1.2.840.10008.5.1.4.1.2.4.2': exports.CompositeInstanceRootRetrieveMOVE,
  '1.2.840.10008.5.1.4.1.2.4.3': exports.CompositeInstanceRootRetrieveGET,
  '1.2.840.10008.5.1.4.1.2.5.3': exports.CompositeInstanceRetrieveWithoutBulkDataGET,
  '1.2.840.10008.5.1.4.31': exports.ModalityWorklistInformationModelFIND,
  '1.2.840.10008.5.1.4.32': exports.GeneralPurposeWorklistManagementMetaSOPClassRetired,
  '1.2.840.10008.5.1.4.32.1': exports.GeneralPurposeWorklistInformationModelFINDRetired,
  '1.2.840.10008.5.1.4.32.2': exports.GeneralPurposeScheduledProcedureStepSOPClassRetired,
  '1.2.840.10008.5.1.4.32.3': exports.GeneralPurposePerformedProcedureStepSOPClassRetired,
  '1.2.840.10008.5.1.4.33': exports.InstanceAvailabilityNotificationSOPClass,
  '1.2.840.10008.5.1.4.34.1': exports.RTBeamsDeliveryInstructionStorageTrialRetired,
  '1.2.840.10008.5.1.4.34.2': exports.RTConventionalMachineVerificationTrialRetired,
  '1.2.840.10008.5.1.4.34.3': exports.RTIonMachineVerificationTrialRetired,
  '1.2.840.10008.5.1.4.34.4': exports.UnifiedWorklistAndProcedureStepServiceClassTrialRetired,
  '1.2.840.10008.5.1.4.34.4.1': exports.UnifiedProcedureStepPushSOPClassTrialRetired,
  '1.2.840.10008.5.1.4.34.4.2': exports.UnifiedProcedureStepWatchSOPClassTrialRetired,
  '1.2.840.10008.5.1.4.34.4.3': exports.UnifiedProcedureStepPullSOPClassTrialRetired,
  '1.2.840.10008.5.1.4.34.4.4': exports.UnifiedProcedureStepEventSOPClassTrialRetired,
  '1.2.840.10008.5.1.4.34.5': exports.UnifiedWorklistAndProcedureStepSOPInstance,
  '1.2.840.10008.5.1.4.34.6': exports.UnifiedWorklistAndProcedureStepServiceClass,
  '1.2.840.10008.5.1.4.34.6.1': exports.UnifiedProcedureStepPushSOPClass,
  '1.2.840.10008.5.1.4.34.6.2': exports.UnifiedProcedureStepWatchSOPClass,
  '1.2.840.10008.5.1.4.34.6.3': exports.UnifiedProcedureStepPullSOPClass,
  '1.2.840.10008.5.1.4.34.6.4': exports.UnifiedProcedureStepEventSOPClass,
  '1.2.840.10008.5.1.4.34.7': exports.RTBeamsDeliveryInstructionStorage,
  '1.2.840.10008.5.1.4.34.8': exports.RTConventionalMachineVerification,
  '1.2.840.10008.5.1.4.34.9': exports.RTIonMachineVerification,
  '1.2.840.10008.5.1.4.37.1': exports.GeneralRelevantPatientInformationQuery,
  '1.2.840.10008.5.1.4.37.2': exports.BreastImagingRelevantPatientInformationQuery,
  '1.2.840.10008.5.1.4.37.3': exports.CardiacRelevantPatientInformationQuery,
  '1.2.840.10008.5.1.4.38.1': exports.HangingProtocolStorage,
  '1.2.840.10008.5.1.4.38.2': exports.HangingProtocolInformationModelFIND,
  '1.2.840.10008.5.1.4.38.3': exports.HangingProtocolInformationModelMOVE,
  '1.2.840.10008.5.1.4.38.4': exports.HangingProtocolInformationModelGET,
  '1.2.840.10008.5.1.4.39.1': exports.ColorPaletteStorage,
  '1.2.840.10008.5.1.4.39.2': exports.ColorPaletteInformationModelFIND,
  '1.2.840.10008.5.1.4.39.3': exports.ColorPaletteInformationModelMOVE,
  '1.2.840.10008.5.1.4.39.4': exports.ColorPaletteInformationModelGET,
  '1.2.840.10008.5.1.4.41': exports.ProductCharacteristicsQuerySOPClass,
  '1.2.840.10008.5.1.4.42': exports.SubstanceApprovalQuerySOPClass,
  '1.2.840.10008.5.1.4.43.1': exports.GenericImplantTemplateStorage,
  '1.2.840.10008.5.1.4.43.2': exports.GenericImplantTemplateInformationModelFIND,
  '1.2.840.10008.5.1.4.43.3': exports.GenericImplantTemplateInformationModelMOVE,
  '1.2.840.10008.5.1.4.43.4': exports.GenericImplantTemplateInformationModelGET,
  '1.2.840.10008.5.1.4.44.1': exports.ImplantAssemblyTemplateStorage,
  '1.2.840.10008.5.1.4.44.2': exports.ImplantAssemblyTemplateInformationModelFIND,
  '1.2.840.10008.5.1.4.44.3': exports.ImplantAssemblyTemplateInformationModelMOVE,
  '1.2.840.10008.5.1.4.44.4': exports.ImplantAssemblyTemplateInformationModelGET,
  '1.2.840.10008.5.1.4.45.1': exports.ImplantTemplateGroupStorage,
  '1.2.840.10008.5.1.4.45.2': exports.ImplantTemplateGroupInformationModelFIND,
  '1.2.840.10008.5.1.4.45.3': exports.ImplantTemplateGroupInformationModelMOVE,
  '1.2.840.10008.5.1.4.45.4': exports.ImplantTemplateGroupInformationModelGET,
  '1.2.840.10008.7.1.1': exports.NativeDICOMModel,
  '1.2.840.10008.7.1.2': exports.AbstractMultiDimensionalImageModel,
  '1.2.840.10008.15.0.3.1': exports.dicomDeviceName,
  '1.2.840.10008.15.0.3.2': exports.dicomDescription,
  '1.2.840.10008.15.0.3.3': exports.dicomManufacturer,
  '1.2.840.10008.15.0.3.4': exports.dicomManufacturerModelName,
  '1.2.840.10008.15.0.3.5': exports.dicomSoftwareVersion,
  '1.2.840.10008.15.0.3.6': exports.dicomVendorData,
  '1.2.840.10008.15.0.3.7': exports.dicomAETitle,
  '1.2.840.10008.15.0.3.8': exports.dicomNetworkConnectionReference,
  '1.2.840.10008.15.0.3.9': exports.dicomApplicationCluster,
  '1.2.840.10008.15.0.3.10': exports.dicomAssociationInitiator,
  '1.2.840.10008.15.0.3.11': exports.dicomAssociationAcceptor,
  '1.2.840.10008.15.0.3.12': exports.dicomHostname,
  '1.2.840.10008.15.0.3.13': exports.dicomPort,
  '1.2.840.10008.15.0.3.14': exports.dicomSOPClass,
  '1.2.840.10008.15.0.3.15': exports.dicomTransferRole,
  '1.2.840.10008.15.0.3.16': exports.dicomTransferSyntax,
  '1.2.840.10008.15.0.3.17': exports.dicomPrimaryDeviceType,
  '1.2.840.10008.15.0.3.18': exports.dicomRelatedDeviceReference,
  '1.2.840.10008.15.0.3.19': exports.dicomPreferredCalledAETitle,
  '1.2.840.10008.15.0.3.20': exports.dicomTLSCyphersuite,
  '1.2.840.10008.15.0.3.21': exports.dicomAuthorizedNodeCertificateReference,
  '1.2.840.10008.15.0.3.22': exports.dicomThisNodeCertificateReference,
  '1.2.840.10008.15.0.3.23': exports.dicomInstalled,
  '1.2.840.10008.15.0.3.24': exports.dicomStationName,
  '1.2.840.10008.15.0.3.25': exports.dicomDeviceSerialNumber,
  '1.2.840.10008.15.0.3.26': exports.dicomInstitutionName,
  '1.2.840.10008.15.0.3.27': exports.dicomInstitutionAddress,
  '1.2.840.10008.15.0.3.28': exports.dicomInstitutionDepartmentName,
  '1.2.840.10008.15.0.3.29': exports.dicomIssuerOfPatientID,
  '1.2.840.10008.15.0.3.30': exports.dicomPreferredCallingAETitle,
  '1.2.840.10008.15.0.3.31': exports.dicomSupportedCharacterSet,
  '1.2.840.10008.15.0.4.1': exports.dicomConfigurationRoot,
  '1.2.840.10008.15.0.4.2': exports.dicomDevicesRoot,
  '1.2.840.10008.15.0.4.3': exports.dicomUniqueAETitlesRegistryRoot,
  '1.2.840.10008.15.0.4.4': exports.dicomDevice,
  '1.2.840.10008.15.0.4.5': exports.dicomNetworkAE,
  '1.2.840.10008.15.0.4.6': exports.dicomNetworkConnection,
  '1.2.840.10008.15.0.4.7': exports.dicomUniqueAETitle,
  '1.2.840.10008.15.0.4.8': exports.dicomTransferCapability,
  '1.2.840.10008.15.1.1': exports.UniversalCoordinatedTime,
