#! /usr/bin/env coffee
#

printf = require("printf")

##
#
# Dicom Element
#
# Holds the data pulled from the 2014 standard.
##
class Element
  constructor: (@tag, @name, @vr, @vm, @mask, @retired) ->
    @tag_str = printf "%08X", @tag
    if not @vr
      if @_is_private_creator()
        @vr = 'LO'
      else if @_is_group_length()
        @vr = 'UL'
      else
        @vr = 'UN'

  _is_private_creator: () ->
    group = @tag >> 16
    elem = @tag & 0xFFFF
    (group & 1) and (group > 8) and (elem >= 0x10) and (elem <= 0xFF)

  _is_private_tag: () ->
    group = @tag >> 16
    (group & 1) and (group > 8)

  _is_group_length: () ->
    elem = @tag & 0xFFFF
    return elem == 0

  log_summary: () ->
    summary =
      tag: printf("%08x", @tag)
      name: @name
      vr: @vr

##
# Get the Dicom Element for the tag
#
# tag may be numeric, representing the numeric dicom tag,
# or a string, representing the symbolic name.
#
##
for_tag = (tag) ->
  switch typeof tag
    when 'number'
      tag_str = printf '%08x', tag
      el = _TAG_DICT[tag_str]
      if el?
        return el
      for [_, mask, base] in _TAG_MASKS
        # console.log printf("tag: %08x considering %08x:%08x", tag, mask, base)
        t_m = (tag & mask)
        if t_m == base
          base_str = printf '%08x', base
          b_el = _TAG_DICT[base_str]
          el = new Element(tag, b_el.name, b_el.vr, b_el.vm, b_el.mask)
          return el
      return new Element(tag)
    when 'string'
      if /[0-9A-F]{8}/.test(tag)
        return for_tag parseInt(tag, 16)
      else
        return exports[tag]
    when 'object'
      return for_tag tag.tag


##
# calculate bit masks and base tags for repeating elements
##
calc_bitmasks = (masks) ->
  counts_and_masks = for mask in masks
    mask_cnt = _mask_count mask
    and_mask = mask.replace(/[^xX]/g, 'F')
    and_mask = and_mask.replace(/[xX]/g, '0')
    base_tag = mask.replace(/[xX]/g, '0')
    [mask_cnt, parseInt(and_mask, 16), parseInt(base_tag, 16)]
  counts_and_masks = counts_and_masks.filter (x) ->
    x[0] <= 2
  counts_and_masks.sort()

_mask_count = (str) ->
  count = 0
  for x in str
    if x in ['x', 'X']
      count++
  return count

##
# Find matching tags.
#
##
find = (regex) ->
  for tag_str, el of _TAG_DICT
    if regex.test(tag_str) or regex.test(el.name)
      console.log el
  undefined

exports.find = find
exports.for_tag = for_tag
exports.calc_bitmasks = calc_bitmasks

_TAG_MASKS = []
# everything past this will be auto-generated. do not modfify
# HERE BE DRAGONS
exports.CommandGroupLength = new Element(0, 'CommandGroupLength', 'UL', '1', '00000000', true)
exports.CommandLengthToEnd = new Element(1, 'CommandLengthToEnd', 'UL', '1', '00000001', true)
exports.AffectedSOPClassUID = new Element(2, 'AffectedSOPClassUID', 'UI', '1', '00000002', true)
exports.RequestedSOPClassUID = new Element(3, 'RequestedSOPClassUID', 'UI', '1', '00000003', true)
exports.CommandRecognitionCode = new Element(16, 'CommandRecognitionCode', 'SH', '1', '00000010', true)
exports.CommandField = new Element(256, 'CommandField', 'US', '1', '00000100', true)
exports.MessageID = new Element(272, 'MessageID', 'US', '1', '00000110', true)
exports.MessageIDBeingRespondedTo = new Element(288, 'MessageIDBeingRespondedTo', 'US', '1', '00000120', true)
exports.Initiator = new Element(512, 'Initiator', 'AE', '1', '00000200', true)
exports.Receiver = new Element(768, 'Receiver', 'AE', '1', '00000300', true)
exports.FindLocation = new Element(1024, 'FindLocation', 'AE', '1', '00000400', true)
exports.MoveDestination = new Element(1536, 'MoveDestination', 'AE', '1', '00000600', true)
exports.Priority = new Element(1792, 'Priority', 'US', '1', '00000700', true)
exports.CommandDataSetType = new Element(2048, 'CommandDataSetType', 'US', '1', '00000800', true)
exports.NumberOfMatches = new Element(2128, 'NumberOfMatches', 'US', '1', '00000850', true)
exports.ResponseSequenceNumber = new Element(2144, 'ResponseSequenceNumber', 'US', '1', '00000860', true)
exports.Status = new Element(2304, 'Status', 'US', '1', '00000900', true)
exports.OffendingElement = new Element(2305, 'OffendingElement', 'AT', '1-n', '00000901', true)
exports.ErrorComment = new Element(2306, 'ErrorComment', 'LO', '1', '00000902', true)
exports.ErrorID = new Element(2307, 'ErrorID', 'US', '1', '00000903', true)
exports.AffectedSOPInstanceUID = new Element(4096, 'AffectedSOPInstanceUID', 'UI', '1', '00001000', true)
exports.RequestedSOPInstanceUID = new Element(4097, 'RequestedSOPInstanceUID', 'UI', '1', '00001001', true)
exports.EventTypeID = new Element(4098, 'EventTypeID', 'US', '1', '00001002', true)
exports.AttributeIdentifierList = new Element(4101, 'AttributeIdentifierList', 'AT', '1-n', '00001005', true)
exports.ActionTypeID = new Element(4104, 'ActionTypeID', 'US', '1', '00001008', true)
exports.NumberOfRemainingSuboperations = new Element(4128, 'NumberOfRemainingSuboperations', 'US', '1', '00001020', true)
exports.NumberOfCompletedSuboperations = new Element(4129, 'NumberOfCompletedSuboperations', 'US', '1', '00001021', true)
exports.NumberOfFailedSuboperations = new Element(4130, 'NumberOfFailedSuboperations', 'US', '1', '00001022', true)
exports.NumberOfWarningSuboperations = new Element(4131, 'NumberOfWarningSuboperations', 'US', '1', '00001023', true)
exports.MoveOriginatorApplicationEntityTitle = new Element(4144, 'MoveOriginatorApplicationEntityTitle', 'AE', '1', '00001030', true)
exports.MoveOriginatorMessageID = new Element(4145, 'MoveOriginatorMessageID', 'US', '1', '00001031', true)
exports.DialogReceiver = new Element(16384, 'DialogReceiver', 'LT', '1', '00004000', true)
exports.TerminalType = new Element(16400, 'TerminalType', 'LT', '1', '00004010', true)
exports.MessageSetID = new Element(20496, 'MessageSetID', 'SH', '1', '00005010', true)
exports.EndMessageID = new Element(20512, 'EndMessageID', 'SH', '1', '00005020', true)
exports.DisplayFormat = new Element(20752, 'DisplayFormat', 'LT', '1', '00005110', true)
exports.PagePositionID = new Element(20768, 'PagePositionID', 'LT', '1', '00005120', true)
exports.TextFormatID = new Element(20784, 'TextFormatID', 'CS', '1', '00005130', true)
exports.NormalReverse = new Element(20800, 'NormalReverse', 'CS', '1', '00005140', true)
exports.AddGrayScale = new Element(20816, 'AddGrayScale', 'CS', '1', '00005150', true)
exports.Borders = new Element(20832, 'Borders', 'CS', '1', '00005160', true)
exports.Copies = new Element(20848, 'Copies', 'IS', '1', '00005170', true)
exports.CommandMagnificationType = new Element(20864, 'CommandMagnificationType', 'CS', '1', '00005180', true)
exports.Erase = new Element(20880, 'Erase', 'CS', '1', '00005190', true)
exports.Print = new Element(20896, 'Print', 'CS', '1', '000051A0', true)
exports.Overlays = new Element(20912, 'Overlays', 'US', '1-n', '000051B0', true)
exports.FileMetaInformationGroupLength = new Element(131072, 'FileMetaInformationGroupLength', 'UL', '1', '00020000', undefined)
exports.FileMetaInformationVersion = new Element(131073, 'FileMetaInformationVersion', 'OB', '1', '00020001', undefined)
exports.MediaStorageSOPClassUID = new Element(131074, 'MediaStorageSOPClassUID', 'UI', '1', '00020002', undefined)
exports.MediaStorageSOPInstanceUID = new Element(131075, 'MediaStorageSOPInstanceUID', 'UI', '1', '00020003', undefined)
exports.TransferSyntaxUID = new Element(131088, 'TransferSyntaxUID', 'UI', '1', '00020010', undefined)
exports.ImplementationClassUID = new Element(131090, 'ImplementationClassUID', 'UI', '1', '00020012', undefined)
exports.ImplementationVersionName = new Element(131091, 'ImplementationVersionName', 'SH', '1', '00020013', undefined)
exports.SourceApplicationEntityTitle = new Element(131094, 'SourceApplicationEntityTitle', 'AE', '1', '00020016', undefined)
exports.SendingApplicationEntityTitle = new Element(131095, 'SendingApplicationEntityTitle', 'AE', '1', '00020017', undefined)
exports.ReceivingApplicationEntityTitle = new Element(131096, 'ReceivingApplicationEntityTitle', 'AE', '1', '00020018', undefined)
exports.PrivateInformationCreatorUID = new Element(131328, 'PrivateInformationCreatorUID', 'UI', '1', '00020100', undefined)
exports.PrivateInformation = new Element(131330, 'PrivateInformation', 'OB', '1', '00020102', undefined)
exports.FileSetID = new Element(266544, 'FileSetID', 'CS', '1', '00041130', undefined)
exports.FileSetDescriptorFileID = new Element(266561, 'FileSetDescriptorFileID', 'CS', '1-8', '00041141', undefined)
exports.SpecificCharacterSetOfFileSetDescriptorFile = new Element(266562, 'SpecificCharacterSetOfFileSetDescriptorFile', 'CS', '1', '00041142', undefined)
exports.OffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity = new Element(266752, 'OffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity', 'UL', '1', '00041200', undefined)
exports.OffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity = new Element(266754, 'OffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity', 'UL', '1', '00041202', undefined)
exports.FileSetConsistencyFlag = new Element(266770, 'FileSetConsistencyFlag', 'US', '1', '00041212', undefined)
exports.DirectoryRecordSequence = new Element(266784, 'DirectoryRecordSequence', 'SQ', '1', '00041220', undefined)
exports.OffsetOfTheNextDirectoryRecord = new Element(267264, 'OffsetOfTheNextDirectoryRecord', 'UL', '1', '00041400', undefined)
exports.RecordInUseFlag = new Element(267280, 'RecordInUseFlag', 'US', '1', '00041410', undefined)
exports.OffsetOfReferencedLowerLevelDirectoryEntity = new Element(267296, 'OffsetOfReferencedLowerLevelDirectoryEntity', 'UL', '1', '00041420', undefined)
exports.DirectoryRecordType = new Element(267312, 'DirectoryRecordType', 'CS', '1', '00041430', undefined)
exports.PrivateRecordUID = new Element(267314, 'PrivateRecordUID', 'UI', '1', '00041432', undefined)
exports.ReferencedFileID = new Element(267520, 'ReferencedFileID', 'CS', '1-8', '00041500', undefined)
exports.MRDRDirectoryRecordOffset = new Element(267524, 'MRDRDirectoryRecordOffset', 'UL', '1', '00041504', true)
exports.ReferencedSOPClassUIDInFile = new Element(267536, 'ReferencedSOPClassUIDInFile', 'UI', '1', '00041510', undefined)
exports.ReferencedSOPInstanceUIDInFile = new Element(267537, 'ReferencedSOPInstanceUIDInFile', 'UI', '1', '00041511', undefined)
exports.ReferencedTransferSyntaxUIDInFile = new Element(267538, 'ReferencedTransferSyntaxUIDInFile', 'UI', '1', '00041512', undefined)
exports.ReferencedRelatedGeneralSOPClassUIDInFile = new Element(267546, 'ReferencedRelatedGeneralSOPClassUIDInFile', 'UI', '1-n', '0004151A', undefined)
exports.NumberOfReferences = new Element(267776, 'NumberOfReferences', 'UL', '1', '00041600', true)
exports.LengthToEnd = new Element(524289, 'LengthToEnd', 'UL', '1', '00080001', true)
exports.SpecificCharacterSet = new Element(524293, 'SpecificCharacterSet', 'CS', '1-n', '00080005', undefined)
exports.LanguageCodeSequence = new Element(524294, 'LanguageCodeSequence', 'SQ', '1', '00080006', undefined)
exports.ImageType = new Element(524296, 'ImageType', 'CS', '2-n', '00080008', undefined)
exports.RecognitionCode = new Element(524304, 'RecognitionCode', 'SH', '1', '00080010', true)
exports.InstanceCreationDate = new Element(524306, 'InstanceCreationDate', 'DA', '1', '00080012', undefined)
exports.InstanceCreationTime = new Element(524307, 'InstanceCreationTime', 'TM', '1', '00080013', undefined)
exports.InstanceCreatorUID = new Element(524308, 'InstanceCreatorUID', 'UI', '1', '00080014', undefined)
exports.InstanceCoercionDateTime = new Element(524309, 'InstanceCoercionDateTime', 'DT', '1', '00080015', undefined)
exports.SOPClassUID = new Element(524310, 'SOPClassUID', 'UI', '1', '00080016', undefined)
exports.SOPInstanceUID = new Element(524312, 'SOPInstanceUID', 'UI', '1', '00080018', undefined)
exports.RelatedGeneralSOPClassUID = new Element(524314, 'RelatedGeneralSOPClassUID', 'UI', '1-n', '0008001A', undefined)
exports.OriginalSpecializedSOPClassUID = new Element(524315, 'OriginalSpecializedSOPClassUID', 'UI', '1', '0008001B', undefined)
exports.StudyDate = new Element(524320, 'StudyDate', 'DA', '1', '00080020', undefined)
exports.SeriesDate = new Element(524321, 'SeriesDate', 'DA', '1', '00080021', undefined)
exports.AcquisitionDate = new Element(524322, 'AcquisitionDate', 'DA', '1', '00080022', undefined)
exports.ContentDate = new Element(524323, 'ContentDate', 'DA', '1', '00080023', undefined)
exports.OverlayDate = new Element(524324, 'OverlayDate', 'DA', '1', '00080024', true)
exports.CurveDate = new Element(524325, 'CurveDate', 'DA', '1', '00080025', true)
exports.AcquisitionDateTime = new Element(524330, 'AcquisitionDateTime', 'DT', '1', '0008002A', undefined)
exports.StudyTime = new Element(524336, 'StudyTime', 'TM', '1', '00080030', undefined)
exports.SeriesTime = new Element(524337, 'SeriesTime', 'TM', '1', '00080031', undefined)
exports.AcquisitionTime = new Element(524338, 'AcquisitionTime', 'TM', '1', '00080032', undefined)
exports.ContentTime = new Element(524339, 'ContentTime', 'TM', '1', '00080033', undefined)
exports.OverlayTime = new Element(524340, 'OverlayTime', 'TM', '1', '00080034', true)
exports.CurveTime = new Element(524341, 'CurveTime', 'TM', '1', '00080035', true)
exports.DataSetType = new Element(524352, 'DataSetType', 'US', '1', '00080040', true)
exports.DataSetSubtype = new Element(524353, 'DataSetSubtype', 'LO', '1', '00080041', true)
exports.NuclearMedicineSeriesType = new Element(524354, 'NuclearMedicineSeriesType', 'CS', '1', '00080042', true)
exports.AccessionNumber = new Element(524368, 'AccessionNumber', 'SH', '1', '00080050', undefined)
exports.IssuerOfAccessionNumberSequence = new Element(524369, 'IssuerOfAccessionNumberSequence', 'SQ', '1', '00080051', undefined)
exports.QueryRetrieveLevel = new Element(524370, 'QueryRetrieveLevel', 'CS', '1', '00080052', undefined)
exports.QueryRetrieveView = new Element(524371, 'QueryRetrieveView', 'CS', '1', '00080053', undefined)
exports.RetrieveAETitle = new Element(524372, 'RetrieveAETitle', 'AE', '1-n', '00080054', undefined)
exports.InstanceAvailability = new Element(524374, 'InstanceAvailability', 'CS', '1', '00080056', undefined)
exports.FailedSOPInstanceUIDList = new Element(524376, 'FailedSOPInstanceUIDList', 'UI', '1-n', '00080058', undefined)
exports.Modality = new Element(524384, 'Modality', 'CS', '1', '00080060', undefined)
exports.ModalitiesInStudy = new Element(524385, 'ModalitiesInStudy', 'CS', '1-n', '00080061', undefined)
exports.SOPClassesInStudy = new Element(524386, 'SOPClassesInStudy', 'UI', '1-n', '00080062', undefined)
exports.ConversionType = new Element(524388, 'ConversionType', 'CS', '1', '00080064', undefined)
exports.PresentationIntentType = new Element(524392, 'PresentationIntentType', 'CS', '1', '00080068', undefined)
exports.Manufacturer = new Element(524400, 'Manufacturer', 'LO', '1', '00080070', undefined)
exports.InstitutionName = new Element(524416, 'InstitutionName', 'LO', '1', '00080080', undefined)
exports.InstitutionAddress = new Element(524417, 'InstitutionAddress', 'ST', '1', '00080081', undefined)
exports.InstitutionCodeSequence = new Element(524418, 'InstitutionCodeSequence', 'SQ', '1', '00080082', undefined)
exports.ReferringPhysicianName = new Element(524432, 'ReferringPhysicianName', 'PN', '1', '00080090', undefined)
exports.ReferringPhysicianAddress = new Element(524434, 'ReferringPhysicianAddress', 'ST', '1', '00080092', undefined)
exports.ReferringPhysicianTelephoneNumbers = new Element(524436, 'ReferringPhysicianTelephoneNumbers', 'SH', '1-n', '00080094', undefined)
exports.ReferringPhysicianIdentificationSequence = new Element(524438, 'ReferringPhysicianIdentificationSequence', 'SQ', '1', '00080096', undefined)
exports.CodeValue = new Element(524544, 'CodeValue', 'SH', '1', '00080100', undefined)
exports.ExtendedCodeValue = new Element(524545, 'ExtendedCodeValue', 'LO', '1', '00080101', undefined)
exports.CodingSchemeDesignator = new Element(524546, 'CodingSchemeDesignator', 'SH', '1', '00080102', undefined)
exports.CodingSchemeVersion = new Element(524547, 'CodingSchemeVersion', 'SH', '1', '00080103', undefined)
exports.CodeMeaning = new Element(524548, 'CodeMeaning', 'LO', '1', '00080104', undefined)
exports.MappingResource = new Element(524549, 'MappingResource', 'CS', '1', '00080105', undefined)
exports.ContextGroupVersion = new Element(524550, 'ContextGroupVersion', 'DT', '1', '00080106', undefined)
exports.ContextGroupLocalVersion = new Element(524551, 'ContextGroupLocalVersion', 'DT', '1', '00080107', undefined)
exports.ExtendedCodeMeaning = new Element(524552, 'ExtendedCodeMeaning', 'LT', '1', '00080108', undefined)
exports.ContextGroupExtensionFlag = new Element(524555, 'ContextGroupExtensionFlag', 'CS', '1', '0008010B', undefined)
exports.CodingSchemeUID = new Element(524556, 'CodingSchemeUID', 'UI', '1', '0008010C', undefined)
exports.ContextGroupExtensionCreatorUID = new Element(524557, 'ContextGroupExtensionCreatorUID', 'UI', '1', '0008010D', undefined)
exports.ContextIdentifier = new Element(524559, 'ContextIdentifier', 'CS', '1', '0008010F', undefined)
exports.CodingSchemeIdentificationSequence = new Element(524560, 'CodingSchemeIdentificationSequence', 'SQ', '1', '00080110', undefined)
exports.CodingSchemeRegistry = new Element(524562, 'CodingSchemeRegistry', 'LO', '1', '00080112', undefined)
exports.CodingSchemeExternalID = new Element(524564, 'CodingSchemeExternalID', 'ST', '1', '00080114', undefined)
exports.CodingSchemeName = new Element(524565, 'CodingSchemeName', 'ST', '1', '00080115', undefined)
exports.CodingSchemeResponsibleOrganization = new Element(524566, 'CodingSchemeResponsibleOrganization', 'ST', '1', '00080116', undefined)
exports.ContextUID = new Element(524567, 'ContextUID', 'UI', '1', '00080117', undefined)
exports.TimezoneOffsetFromUTC = new Element(524801, 'TimezoneOffsetFromUTC', 'SH', '1', '00080201', undefined)
exports.NetworkID = new Element(528384, 'NetworkID', 'AE', '1', '00081000', true)
exports.StationName = new Element(528400, 'StationName', 'SH', '1', '00081010', undefined)
exports.StudyDescription = new Element(528432, 'StudyDescription', 'LO', '1', '00081030', undefined)
exports.ProcedureCodeSequence = new Element(528434, 'ProcedureCodeSequence', 'SQ', '1', '00081032', undefined)
exports.SeriesDescription = new Element(528446, 'SeriesDescription', 'LO', '1', '0008103E', undefined)
exports.SeriesDescriptionCodeSequence = new Element(528447, 'SeriesDescriptionCodeSequence', 'SQ', '1', '0008103F', undefined)
exports.InstitutionalDepartmentName = new Element(528448, 'InstitutionalDepartmentName', 'LO', '1', '00081040', undefined)
exports.PhysiciansOfRecord = new Element(528456, 'PhysiciansOfRecord', 'PN', '1-n', '00081048', undefined)
exports.PhysiciansOfRecordIdentificationSequence = new Element(528457, 'PhysiciansOfRecordIdentificationSequence', 'SQ', '1', '00081049', undefined)
exports.PerformingPhysicianName = new Element(528464, 'PerformingPhysicianName', 'PN', '1-n', '00081050', undefined)
exports.PerformingPhysicianIdentificationSequence = new Element(528466, 'PerformingPhysicianIdentificationSequence', 'SQ', '1', '00081052', undefined)
exports.NameOfPhysiciansReadingStudy = new Element(528480, 'NameOfPhysiciansReadingStudy', 'PN', '1-n', '00081060', undefined)
exports.PhysiciansReadingStudyIdentificationSequence = new Element(528482, 'PhysiciansReadingStudyIdentificationSequence', 'SQ', '1', '00081062', undefined)
exports.OperatorsName = new Element(528496, 'OperatorsName', 'PN', '1-n', '00081070', undefined)
exports.OperatorIdentificationSequence = new Element(528498, 'OperatorIdentificationSequence', 'SQ', '1', '00081072', undefined)
exports.AdmittingDiagnosesDescription = new Element(528512, 'AdmittingDiagnosesDescription', 'LO', '1-n', '00081080', undefined)
exports.AdmittingDiagnosesCodeSequence = new Element(528516, 'AdmittingDiagnosesCodeSequence', 'SQ', '1', '00081084', undefined)
exports.ManufacturerModelName = new Element(528528, 'ManufacturerModelName', 'LO', '1', '00081090', undefined)
exports.ReferencedResultsSequence = new Element(528640, 'ReferencedResultsSequence', 'SQ', '1', '00081100', true)
exports.ReferencedStudySequence = new Element(528656, 'ReferencedStudySequence', 'SQ', '1', '00081110', undefined)
exports.ReferencedPerformedProcedureStepSequence = new Element(528657, 'ReferencedPerformedProcedureStepSequence', 'SQ', '1', '00081111', undefined)
exports.ReferencedSeriesSequence = new Element(528661, 'ReferencedSeriesSequence', 'SQ', '1', '00081115', undefined)
exports.ReferencedPatientSequence = new Element(528672, 'ReferencedPatientSequence', 'SQ', '1', '00081120', undefined)
exports.ReferencedVisitSequence = new Element(528677, 'ReferencedVisitSequence', 'SQ', '1', '00081125', undefined)
exports.ReferencedOverlaySequence = new Element(528688, 'ReferencedOverlaySequence', 'SQ', '1', '00081130', true)
exports.ReferencedStereometricInstanceSequence = new Element(528692, 'ReferencedStereometricInstanceSequence', 'SQ', '1', '00081134', undefined)
exports.ReferencedWaveformSequence = new Element(528698, 'ReferencedWaveformSequence', 'SQ', '1', '0008113A', undefined)
exports.ReferencedImageSequence = new Element(528704, 'ReferencedImageSequence', 'SQ', '1', '00081140', undefined)
exports.ReferencedCurveSequence = new Element(528709, 'ReferencedCurveSequence', 'SQ', '1', '00081145', true)
exports.ReferencedInstanceSequence = new Element(528714, 'ReferencedInstanceSequence', 'SQ', '1', '0008114A', undefined)
exports.ReferencedRealWorldValueMappingInstanceSequence = new Element(528715, 'ReferencedRealWorldValueMappingInstanceSequence', 'SQ', '1', '0008114B', undefined)
exports.ReferencedSOPClassUID = new Element(528720, 'ReferencedSOPClassUID', 'UI', '1', '00081150', undefined)
exports.ReferencedSOPInstanceUID = new Element(528725, 'ReferencedSOPInstanceUID', 'UI', '1', '00081155', undefined)
exports.SOPClassesSupported = new Element(528730, 'SOPClassesSupported', 'UI', '1-n', '0008115A', undefined)
exports.ReferencedFrameNumber = new Element(528736, 'ReferencedFrameNumber', 'IS', '1-n', '00081160', undefined)
exports.SimpleFrameList = new Element(528737, 'SimpleFrameList', 'UL', '1-n', '00081161', undefined)
exports.CalculatedFrameList = new Element(528738, 'CalculatedFrameList', 'UL', '3-3n', '00081162', undefined)
exports.TimeRange = new Element(528739, 'TimeRange', 'FD', '2', '00081163', undefined)
exports.FrameExtractionSequence = new Element(528740, 'FrameExtractionSequence', 'SQ', '1', '00081164', undefined)
exports.MultiFrameSourceSOPInstanceUID = new Element(528743, 'MultiFrameSourceSOPInstanceUID', 'UI', '1', '00081167', undefined)
exports.RetrieveURL = new Element(528784, 'RetrieveURL', 'UT', '1', '00081190', undefined)
exports.TransactionUID = new Element(528789, 'TransactionUID', 'UI', '1', '00081195', undefined)
exports.WarningReason = new Element(528790, 'WarningReason', 'US', '1', '00081196', undefined)
exports.FailureReason = new Element(528791, 'FailureReason', 'US', '1', '00081197', undefined)
exports.FailedSOPSequence = new Element(528792, 'FailedSOPSequence', 'SQ', '1', '00081198', undefined)
exports.ReferencedSOPSequence = new Element(528793, 'ReferencedSOPSequence', 'SQ', '1', '00081199', undefined)
exports.StudiesContainingOtherReferencedInstancesSequence = new Element(528896, 'StudiesContainingOtherReferencedInstancesSequence', 'SQ', '1', '00081200', undefined)
exports.RelatedSeriesSequence = new Element(528976, 'RelatedSeriesSequence', 'SQ', '1', '00081250', undefined)
exports.LossyImageCompressionRetired = new Element(532752, 'LossyImageCompressionRetired', 'CS', '1', '00082110', true)
exports.DerivationDescription = new Element(532753, 'DerivationDescription', 'ST', '1', '00082111', undefined)
exports.SourceImageSequence = new Element(532754, 'SourceImageSequence', 'SQ', '1', '00082112', undefined)
exports.StageName = new Element(532768, 'StageName', 'SH', '1', '00082120', undefined)
exports.StageNumber = new Element(532770, 'StageNumber', 'IS', '1', '00082122', undefined)
exports.NumberOfStages = new Element(532772, 'NumberOfStages', 'IS', '1', '00082124', undefined)
exports.ViewName = new Element(532775, 'ViewName', 'SH', '1', '00082127', undefined)
exports.ViewNumber = new Element(532776, 'ViewNumber', 'IS', '1', '00082128', undefined)
exports.NumberOfEventTimers = new Element(532777, 'NumberOfEventTimers', 'IS', '1', '00082129', undefined)
exports.NumberOfViewsInStage = new Element(532778, 'NumberOfViewsInStage', 'IS', '1', '0008212A', undefined)
exports.EventElapsedTimes = new Element(532784, 'EventElapsedTimes', 'DS', '1-n', '00082130', undefined)
exports.EventTimerNames = new Element(532786, 'EventTimerNames', 'LO', '1-n', '00082132', undefined)
exports.EventTimerSequence = new Element(532787, 'EventTimerSequence', 'SQ', '1', '00082133', undefined)
exports.EventTimeOffset = new Element(532788, 'EventTimeOffset', 'FD', '1', '00082134', undefined)
exports.EventCodeSequence = new Element(532789, 'EventCodeSequence', 'SQ', '1', '00082135', undefined)
exports.StartTrim = new Element(532802, 'StartTrim', 'IS', '1', '00082142', undefined)
exports.StopTrim = new Element(532803, 'StopTrim', 'IS', '1', '00082143', undefined)
exports.RecommendedDisplayFrameRate = new Element(532804, 'RecommendedDisplayFrameRate', 'IS', '1', '00082144', undefined)
exports.TransducerPosition = new Element(532992, 'TransducerPosition', 'CS', '1', '00082200', true)
exports.TransducerOrientation = new Element(532996, 'TransducerOrientation', 'CS', '1', '00082204', true)
exports.AnatomicStructure = new Element(533000, 'AnatomicStructure', 'CS', '1', '00082208', true)
exports.AnatomicRegionSequence = new Element(533016, 'AnatomicRegionSequence', 'SQ', '1', '00082218', undefined)
exports.AnatomicRegionModifierSequence = new Element(533024, 'AnatomicRegionModifierSequence', 'SQ', '1', '00082220', undefined)
exports.PrimaryAnatomicStructureSequence = new Element(533032, 'PrimaryAnatomicStructureSequence', 'SQ', '1', '00082228', undefined)
exports.AnatomicStructureSpaceOrRegionSequence = new Element(533033, 'AnatomicStructureSpaceOrRegionSequence', 'SQ', '1', '00082229', undefined)
exports.PrimaryAnatomicStructureModifierSequence = new Element(533040, 'PrimaryAnatomicStructureModifierSequence', 'SQ', '1', '00082230', undefined)
exports.TransducerPositionSequence = new Element(533056, 'TransducerPositionSequence', 'SQ', '1', '00082240', true)
exports.TransducerPositionModifierSequence = new Element(533058, 'TransducerPositionModifierSequence', 'SQ', '1', '00082242', true)
exports.TransducerOrientationSequence = new Element(533060, 'TransducerOrientationSequence', 'SQ', '1', '00082244', true)
exports.TransducerOrientationModifierSequence = new Element(533062, 'TransducerOrientationModifierSequence', 'SQ', '1', '00082246', true)
exports.AnatomicStructureSpaceOrRegionCodeSequenceTrial = new Element(533073, 'AnatomicStructureSpaceOrRegionCodeSequenceTrial', 'SQ', '1', '00082251', true)
exports.AnatomicPortalOfEntranceCodeSequenceTrial = new Element(533075, 'AnatomicPortalOfEntranceCodeSequenceTrial', 'SQ', '1', '00082253', true)
exports.AnatomicApproachDirectionCodeSequenceTrial = new Element(533077, 'AnatomicApproachDirectionCodeSequenceTrial', 'SQ', '1', '00082255', true)
exports.AnatomicPerspectiveDescriptionTrial = new Element(533078, 'AnatomicPerspectiveDescriptionTrial', 'ST', '1', '00082256', true)
exports.AnatomicPerspectiveCodeSequenceTrial = new Element(533079, 'AnatomicPerspectiveCodeSequenceTrial', 'SQ', '1', '00082257', true)
exports.AnatomicLocationOfExaminingInstrumentDescriptionTrial = new Element(533080, 'AnatomicLocationOfExaminingInstrumentDescriptionTrial', 'ST', '1', '00082258', true)
exports.AnatomicLocationOfExaminingInstrumentCodeSequenceTrial = new Element(533081, 'AnatomicLocationOfExaminingInstrumentCodeSequenceTrial', 'SQ', '1', '00082259', true)
exports.AnatomicStructureSpaceOrRegionModifierCodeSequenceTrial = new Element(533082, 'AnatomicStructureSpaceOrRegionModifierCodeSequenceTrial', 'SQ', '1', '0008225A', true)
exports.OnAxisBackgroundAnatomicStructureCodeSequenceTrial = new Element(533084, 'OnAxisBackgroundAnatomicStructureCodeSequenceTrial', 'SQ', '1', '0008225C', true)
exports.AlternateRepresentationSequence = new Element(536577, 'AlternateRepresentationSequence', 'SQ', '1', '00083001', undefined)
exports.IrradiationEventUID = new Element(536592, 'IrradiationEventUID', 'UI', '1-n', '00083010', undefined)
exports.SourceIrradiationEventSequence = new Element(536593, 'SourceIrradiationEventSequence', 'SQ', '1', '00083011', undefined)
exports.RadiopharmaceuticalAdministrationEventUID = new Element(536594, 'RadiopharmaceuticalAdministrationEventUID', 'UI', '1', '00083012', undefined)
exports.IdentifyingComments = new Element(540672, 'IdentifyingComments', 'LT', '1', '00084000', true)
exports.FrameType = new Element(561159, 'FrameType', 'CS', '4', '00089007', undefined)
exports.ReferencedImageEvidenceSequence = new Element(561298, 'ReferencedImageEvidenceSequence', 'SQ', '1', '00089092', undefined)
exports.ReferencedRawDataSequence = new Element(561441, 'ReferencedRawDataSequence', 'SQ', '1', '00089121', undefined)
exports.CreatorVersionUID = new Element(561443, 'CreatorVersionUID', 'UI', '1', '00089123', undefined)
exports.DerivationImageSequence = new Element(561444, 'DerivationImageSequence', 'SQ', '1', '00089124', undefined)
exports.SourceImageEvidenceSequence = new Element(561492, 'SourceImageEvidenceSequence', 'SQ', '1', '00089154', undefined)
exports.PixelPresentation = new Element(561669, 'PixelPresentation', 'CS', '1', '00089205', undefined)
exports.VolumetricProperties = new Element(561670, 'VolumetricProperties', 'CS', '1', '00089206', undefined)
exports.VolumeBasedCalculationTechnique = new Element(561671, 'VolumeBasedCalculationTechnique', 'CS', '1', '00089207', undefined)
exports.ComplexImageComponent = new Element(561672, 'ComplexImageComponent', 'CS', '1', '00089208', undefined)
exports.AcquisitionContrast = new Element(561673, 'AcquisitionContrast', 'CS', '1', '00089209', undefined)
exports.DerivationCodeSequence = new Element(561685, 'DerivationCodeSequence', 'SQ', '1', '00089215', undefined)
exports.ReferencedPresentationStateSequence = new Element(561719, 'ReferencedPresentationStateSequence', 'SQ', '1', '00089237', undefined)
exports.ReferencedOtherPlaneSequence = new Element(562192, 'ReferencedOtherPlaneSequence', 'SQ', '1', '00089410', undefined)
exports.FrameDisplaySequence = new Element(562264, 'FrameDisplaySequence', 'SQ', '1', '00089458', undefined)
exports.RecommendedDisplayFrameRateInFloat = new Element(562265, 'RecommendedDisplayFrameRateInFloat', 'FL', '1', '00089459', undefined)
exports.SkipFrameRangeFlag = new Element(562272, 'SkipFrameRangeFlag', 'CS', '1', '00089460', undefined)
exports.PatientName = new Element(1048592, 'PatientName', 'PN', '1', '00100010', undefined)
exports.PatientID = new Element(1048608, 'PatientID', 'LO', '1', '00100020', undefined)
exports.IssuerOfPatientID = new Element(1048609, 'IssuerOfPatientID', 'LO', '1', '00100021', undefined)
exports.TypeOfPatientID = new Element(1048610, 'TypeOfPatientID', 'CS', '1', '00100022', undefined)
exports.IssuerOfPatientIDQualifiersSequence = new Element(1048612, 'IssuerOfPatientIDQualifiersSequence', 'SQ', '1', '00100024', undefined)
exports.PatientBirthDate = new Element(1048624, 'PatientBirthDate', 'DA', '1', '00100030', undefined)
exports.PatientBirthTime = new Element(1048626, 'PatientBirthTime', 'TM', '1', '00100032', undefined)
exports.PatientSex = new Element(1048640, 'PatientSex', 'CS', '1', '00100040', undefined)
exports.PatientInsurancePlanCodeSequence = new Element(1048656, 'PatientInsurancePlanCodeSequence', 'SQ', '1', '00100050', undefined)
exports.PatientPrimaryLanguageCodeSequence = new Element(1048833, 'PatientPrimaryLanguageCodeSequence', 'SQ', '1', '00100101', undefined)
exports.PatientPrimaryLanguageModifierCodeSequence = new Element(1048834, 'PatientPrimaryLanguageModifierCodeSequence', 'SQ', '1', '00100102', undefined)
exports.QualityControlSubject = new Element(1049088, 'QualityControlSubject', 'CS', '1', '00100200', undefined)
exports.QualityControlSubjectTypeCodeSequence = new Element(1049089, 'QualityControlSubjectTypeCodeSequence', 'SQ', '1', '00100201', undefined)
exports.OtherPatientIDs = new Element(1052672, 'OtherPatientIDs', 'LO', '1-n', '00101000', undefined)
exports.OtherPatientNames = new Element(1052673, 'OtherPatientNames', 'PN', '1-n', '00101001', undefined)
exports.OtherPatientIDsSequence = new Element(1052674, 'OtherPatientIDsSequence', 'SQ', '1', '00101002', undefined)
exports.PatientBirthName = new Element(1052677, 'PatientBirthName', 'PN', '1', '00101005', undefined)
exports.PatientAge = new Element(1052688, 'PatientAge', 'AS', '1', '00101010', undefined)
exports.PatientSize = new Element(1052704, 'PatientSize', 'DS', '1', '00101020', undefined)
exports.PatientSizeCodeSequence = new Element(1052705, 'PatientSizeCodeSequence', 'SQ', '1', '00101021', undefined)
exports.PatientWeight = new Element(1052720, 'PatientWeight', 'DS', '1', '00101030', undefined)
exports.PatientAddress = new Element(1052736, 'PatientAddress', 'LO', '1', '00101040', undefined)
exports.InsurancePlanIdentification = new Element(1052752, 'InsurancePlanIdentification', 'LO', '1-n', '00101050', true)
exports.PatientMotherBirthName = new Element(1052768, 'PatientMotherBirthName', 'PN', '1', '00101060', undefined)
exports.MilitaryRank = new Element(1052800, 'MilitaryRank', 'LO', '1', '00101080', undefined)
exports.BranchOfService = new Element(1052801, 'BranchOfService', 'LO', '1', '00101081', undefined)
exports.MedicalRecordLocator = new Element(1052816, 'MedicalRecordLocator', 'LO', '1', '00101090', undefined)
exports.ReferencedPatientPhotoSequence = new Element(1052928, 'ReferencedPatientPhotoSequence', 'SQ', '1', '00101100', undefined)
exports.MedicalAlerts = new Element(1056768, 'MedicalAlerts', 'LO', '1-n', '00102000', undefined)
exports.Allergies = new Element(1057040, 'Allergies', 'LO', '1-n', '00102110', undefined)
exports.CountryOfResidence = new Element(1057104, 'CountryOfResidence', 'LO', '1', '00102150', undefined)
exports.RegionOfResidence = new Element(1057106, 'RegionOfResidence', 'LO', '1', '00102152', undefined)
exports.PatientTelephoneNumbers = new Element(1057108, 'PatientTelephoneNumbers', 'SH', '1-n', '00102154', undefined)
exports.EthnicGroup = new Element(1057120, 'EthnicGroup', 'SH', '1', '00102160', undefined)
exports.Occupation = new Element(1057152, 'Occupation', 'SH', '1', '00102180', undefined)
exports.SmokingStatus = new Element(1057184, 'SmokingStatus', 'CS', '1', '001021A0', undefined)
exports.AdditionalPatientHistory = new Element(1057200, 'AdditionalPatientHistory', 'LT', '1', '001021B0', undefined)
exports.PregnancyStatus = new Element(1057216, 'PregnancyStatus', 'US', '1', '001021C0', undefined)
exports.LastMenstrualDate = new Element(1057232, 'LastMenstrualDate', 'DA', '1', '001021D0', undefined)
exports.PatientReligiousPreference = new Element(1057264, 'PatientReligiousPreference', 'LO', '1', '001021F0', undefined)
exports.PatientSpeciesDescription = new Element(1057281, 'PatientSpeciesDescription', 'LO', '1', '00102201', undefined)
exports.PatientSpeciesCodeSequence = new Element(1057282, 'PatientSpeciesCodeSequence', 'SQ', '1', '00102202', undefined)
exports.PatientSexNeutered = new Element(1057283, 'PatientSexNeutered', 'CS', '1', '00102203', undefined)
exports.AnatomicalOrientationType = new Element(1057296, 'AnatomicalOrientationType', 'CS', '1', '00102210', undefined)
exports.PatientBreedDescription = new Element(1057426, 'PatientBreedDescription', 'LO', '1', '00102292', undefined)
exports.PatientBreedCodeSequence = new Element(1057427, 'PatientBreedCodeSequence', 'SQ', '1', '00102293', undefined)
exports.BreedRegistrationSequence = new Element(1057428, 'BreedRegistrationSequence', 'SQ', '1', '00102294', undefined)
exports.BreedRegistrationNumber = new Element(1057429, 'BreedRegistrationNumber', 'LO', '1', '00102295', undefined)
exports.BreedRegistryCodeSequence = new Element(1057430, 'BreedRegistryCodeSequence', 'SQ', '1', '00102296', undefined)
exports.ResponsiblePerson = new Element(1057431, 'ResponsiblePerson', 'PN', '1', '00102297', undefined)
exports.ResponsiblePersonRole = new Element(1057432, 'ResponsiblePersonRole', 'CS', '1', '00102298', undefined)
exports.ResponsibleOrganization = new Element(1057433, 'ResponsibleOrganization', 'LO', '1', '00102299', undefined)
exports.PatientComments = new Element(1064960, 'PatientComments', 'LT', '1', '00104000', undefined)
exports.ExaminedBodyThickness = new Element(1086513, 'ExaminedBodyThickness', 'FL', '1', '00109431', undefined)
exports.ClinicalTrialSponsorName = new Element(1179664, 'ClinicalTrialSponsorName', 'LO', '1', '00120010', undefined)
exports.ClinicalTrialProtocolID = new Element(1179680, 'ClinicalTrialProtocolID', 'LO', '1', '00120020', undefined)
exports.ClinicalTrialProtocolName = new Element(1179681, 'ClinicalTrialProtocolName', 'LO', '1', '00120021', undefined)
exports.ClinicalTrialSiteID = new Element(1179696, 'ClinicalTrialSiteID', 'LO', '1', '00120030', undefined)
exports.ClinicalTrialSiteName = new Element(1179697, 'ClinicalTrialSiteName', 'LO', '1', '00120031', undefined)
exports.ClinicalTrialSubjectID = new Element(1179712, 'ClinicalTrialSubjectID', 'LO', '1', '00120040', undefined)
exports.ClinicalTrialSubjectReadingID = new Element(1179714, 'ClinicalTrialSubjectReadingID', 'LO', '1', '00120042', undefined)
exports.ClinicalTrialTimePointID = new Element(1179728, 'ClinicalTrialTimePointID', 'LO', '1', '00120050', undefined)
exports.ClinicalTrialTimePointDescription = new Element(1179729, 'ClinicalTrialTimePointDescription', 'ST', '1', '00120051', undefined)
exports.ClinicalTrialCoordinatingCenterName = new Element(1179744, 'ClinicalTrialCoordinatingCenterName', 'LO', '1', '00120060', undefined)
exports.PatientIdentityRemoved = new Element(1179746, 'PatientIdentityRemoved', 'CS', '1', '00120062', undefined)
exports.DeidentificationMethod = new Element(1179747, 'DeidentificationMethod', 'LO', '1-n', '00120063', undefined)
exports.DeidentificationMethodCodeSequence = new Element(1179748, 'DeidentificationMethodCodeSequence', 'SQ', '1', '00120064', undefined)
exports.ClinicalTrialSeriesID = new Element(1179761, 'ClinicalTrialSeriesID', 'LO', '1', '00120071', undefined)
exports.ClinicalTrialSeriesDescription = new Element(1179762, 'ClinicalTrialSeriesDescription', 'LO', '1', '00120072', undefined)
exports.ClinicalTrialProtocolEthicsCommitteeName = new Element(1179777, 'ClinicalTrialProtocolEthicsCommitteeName', 'LO', '1', '00120081', undefined)
exports.ClinicalTrialProtocolEthicsCommitteeApprovalNumber = new Element(1179778, 'ClinicalTrialProtocolEthicsCommitteeApprovalNumber', 'LO', '1', '00120082', undefined)
exports.ConsentForClinicalTrialUseSequence = new Element(1179779, 'ConsentForClinicalTrialUseSequence', 'SQ', '1', '00120083', undefined)
exports.DistributionType = new Element(1179780, 'DistributionType', 'CS', '1', '00120084', undefined)
exports.ConsentForDistributionFlag = new Element(1179781, 'ConsentForDistributionFlag', 'CS', '1', '00120085', undefined)
exports.CADFileFormat = new Element(1310755, 'CADFileFormat', 'ST', '1-n', '00140023', true)
exports.ComponentReferenceSystem = new Element(1310756, 'ComponentReferenceSystem', 'ST', '1-n', '00140024', true)
exports.ComponentManufacturingProcedure = new Element(1310757, 'ComponentManufacturingProcedure', 'ST', '1-n', '00140025', undefined)
exports.ComponentManufacturer = new Element(1310760, 'ComponentManufacturer', 'ST', '1-n', '00140028', undefined)
exports.MaterialThickness = new Element(1310768, 'MaterialThickness', 'DS', '1-n', '00140030', undefined)
exports.MaterialPipeDiameter = new Element(1310770, 'MaterialPipeDiameter', 'DS', '1-n', '00140032', undefined)
exports.MaterialIsolationDiameter = new Element(1310772, 'MaterialIsolationDiameter', 'DS', '1-n', '00140034', undefined)
exports.MaterialGrade = new Element(1310786, 'MaterialGrade', 'ST', '1-n', '00140042', undefined)
exports.MaterialPropertiesDescription = new Element(1310788, 'MaterialPropertiesDescription', 'ST', '1-n', '00140044', undefined)
exports.MaterialPropertiesFileFormatRetired = new Element(1310789, 'MaterialPropertiesFileFormatRetired', 'ST', '1-n', '00140045', true)
exports.MaterialNotes = new Element(1310790, 'MaterialNotes', 'LT', '1', '00140046', undefined)
exports.ComponentShape = new Element(1310800, 'ComponentShape', 'CS', '1', '00140050', undefined)
exports.CurvatureType = new Element(1310802, 'CurvatureType', 'CS', '1', '00140052', undefined)
exports.OuterDiameter = new Element(1310804, 'OuterDiameter', 'DS', '1', '00140054', undefined)
exports.InnerDiameter = new Element(1310806, 'InnerDiameter', 'DS', '1', '00140056', undefined)
exports.ActualEnvironmentalConditions = new Element(1314832, 'ActualEnvironmentalConditions', 'ST', '1', '00141010', undefined)
exports.ExpiryDate = new Element(1314848, 'ExpiryDate', 'DA', '1', '00141020', undefined)
exports.EnvironmentalConditions = new Element(1314880, 'EnvironmentalConditions', 'ST', '1', '00141040', undefined)
exports.EvaluatorSequence = new Element(1318914, 'EvaluatorSequence', 'SQ', '1', '00142002', undefined)
exports.EvaluatorNumber = new Element(1318916, 'EvaluatorNumber', 'IS', '1', '00142004', undefined)
exports.EvaluatorName = new Element(1318918, 'EvaluatorName', 'PN', '1', '00142006', undefined)
exports.EvaluationAttempt = new Element(1318920, 'EvaluationAttempt', 'IS', '1', '00142008', undefined)
exports.IndicationSequence = new Element(1318930, 'IndicationSequence', 'SQ', '1', '00142012', undefined)
exports.IndicationNumber = new Element(1318932, 'IndicationNumber', 'IS', '1', '00142014', undefined)
exports.IndicationLabel = new Element(1318934, 'IndicationLabel', 'SH', '1', '00142016', undefined)
exports.IndicationDescription = new Element(1318936, 'IndicationDescription', 'ST', '1', '00142018', undefined)
exports.IndicationType = new Element(1318938, 'IndicationType', 'CS', '1-n', '0014201A', undefined)
exports.IndicationDisposition = new Element(1318940, 'IndicationDisposition', 'CS', '1', '0014201C', undefined)
exports.IndicationROISequence = new Element(1318942, 'IndicationROISequence', 'SQ', '1', '0014201E', undefined)
exports.IndicationPhysicalPropertySequence = new Element(1318960, 'IndicationPhysicalPropertySequence', 'SQ', '1', '00142030', undefined)
exports.PropertyLabel = new Element(1318962, 'PropertyLabel', 'SH', '1', '00142032', undefined)
exports.CoordinateSystemNumberOfAxes = new Element(1319426, 'CoordinateSystemNumberOfAxes', 'IS', '1', '00142202', undefined)
exports.CoordinateSystemAxesSequence = new Element(1319428, 'CoordinateSystemAxesSequence', 'SQ', '1', '00142204', undefined)
exports.CoordinateSystemAxisDescription = new Element(1319430, 'CoordinateSystemAxisDescription', 'ST', '1', '00142206', undefined)
exports.CoordinateSystemDataSetMapping = new Element(1319432, 'CoordinateSystemDataSetMapping', 'CS', '1', '00142208', undefined)
exports.CoordinateSystemAxisNumber = new Element(1319434, 'CoordinateSystemAxisNumber', 'IS', '1', '0014220A', undefined)
exports.CoordinateSystemAxisType = new Element(1319436, 'CoordinateSystemAxisType', 'CS', '1', '0014220C', undefined)
exports.CoordinateSystemAxisUnits = new Element(1319438, 'CoordinateSystemAxisUnits', 'CS', '1', '0014220E', undefined)
exports.CoordinateSystemAxisValues = new Element(1319440, 'CoordinateSystemAxisValues', 'OB', '1', '00142210', undefined)
exports.CoordinateSystemTransformSequence = new Element(1319456, 'CoordinateSystemTransformSequence', 'SQ', '1', '00142220', undefined)
exports.TransformDescription = new Element(1319458, 'TransformDescription', 'ST', '1', '00142222', undefined)
exports.TransformNumberOfAxes = new Element(1319460, 'TransformNumberOfAxes', 'IS', '1', '00142224', undefined)
exports.TransformOrderOfAxes = new Element(1319462, 'TransformOrderOfAxes', 'IS', '1-n', '00142226', undefined)
exports.TransformedAxisUnits = new Element(1319464, 'TransformedAxisUnits', 'CS', '1', '00142228', undefined)
exports.CoordinateSystemTransformRotationAndScaleMatrix = new Element(1319466, 'CoordinateSystemTransformRotationAndScaleMatrix', 'DS', '1-n', '0014222A', undefined)
exports.CoordinateSystemTransformTranslationMatrix = new Element(1319468, 'CoordinateSystemTransformTranslationMatrix', 'DS', '1-n', '0014222C', undefined)
exports.InternalDetectorFrameTime = new Element(1323025, 'InternalDetectorFrameTime', 'DS', '1', '00143011', undefined)
exports.NumberOfFramesIntegrated = new Element(1323026, 'NumberOfFramesIntegrated', 'DS', '1', '00143012', undefined)
exports.DetectorTemperatureSequence = new Element(1323040, 'DetectorTemperatureSequence', 'SQ', '1', '00143020', undefined)
exports.SensorName = new Element(1323042, 'SensorName', 'ST', '1', '00143022', undefined)
exports.HorizontalOffsetOfSensor = new Element(1323044, 'HorizontalOffsetOfSensor', 'DS', '1', '00143024', undefined)
exports.VerticalOffsetOfSensor = new Element(1323046, 'VerticalOffsetOfSensor', 'DS', '1', '00143026', undefined)
exports.SensorTemperature = new Element(1323048, 'SensorTemperature', 'DS', '1', '00143028', undefined)
exports.DarkCurrentSequence = new Element(1323072, 'DarkCurrentSequence', 'SQ', '1', '00143040', undefined)
exports.DarkCurrentCounts = new Element(1323088, 'DarkCurrentCounts', 'OB or OW', '1', '00143050', undefined)
exports.GainCorrectionReferenceSequence = new Element(1323104, 'GainCorrectionReferenceSequence', 'SQ', '1', '00143060', undefined)
exports.AirCounts = new Element(1323120, 'AirCounts', 'OB or OW', '1', '00143070', undefined)
exports.KVUsedInGainCalibration = new Element(1323121, 'KVUsedInGainCalibration', 'DS', '1', '00143071', undefined)
exports.MAUsedInGainCalibration = new Element(1323122, 'MAUsedInGainCalibration', 'DS', '1', '00143072', undefined)
exports.NumberOfFramesUsedForIntegration = new Element(1323123, 'NumberOfFramesUsedForIntegration', 'DS', '1', '00143073', undefined)
exports.FilterMaterialUsedInGainCalibration = new Element(1323124, 'FilterMaterialUsedInGainCalibration', 'LO', '1', '00143074', undefined)
exports.FilterThicknessUsedInGainCalibration = new Element(1323125, 'FilterThicknessUsedInGainCalibration', 'DS', '1', '00143075', undefined)
exports.DateOfGainCalibration = new Element(1323126, 'DateOfGainCalibration', 'DA', '1', '00143076', undefined)
exports.TimeOfGainCalibration = new Element(1323127, 'TimeOfGainCalibration', 'TM', '1', '00143077', undefined)
exports.BadPixelImage = new Element(1323136, 'BadPixelImage', 'OB', '1', '00143080', undefined)
exports.CalibrationNotes = new Element(1323161, 'CalibrationNotes', 'LT', '1', '00143099', undefined)
exports.PulserEquipmentSequence = new Element(1327106, 'PulserEquipmentSequence', 'SQ', '1', '00144002', undefined)
exports.PulserType = new Element(1327108, 'PulserType', 'CS', '1', '00144004', undefined)
exports.PulserNotes = new Element(1327110, 'PulserNotes', 'LT', '1', '00144006', undefined)
exports.ReceiverEquipmentSequence = new Element(1327112, 'ReceiverEquipmentSequence', 'SQ', '1', '00144008', undefined)
exports.AmplifierType = new Element(1327114, 'AmplifierType', 'CS', '1', '0014400A', undefined)
exports.ReceiverNotes = new Element(1327116, 'ReceiverNotes', 'LT', '1', '0014400C', undefined)
exports.PreAmplifierEquipmentSequence = new Element(1327118, 'PreAmplifierEquipmentSequence', 'SQ', '1', '0014400E', undefined)
exports.PreAmplifierNotes = new Element(1327119, 'PreAmplifierNotes', 'LT', '1', '0014400F', undefined)
exports.TransmitTransducerSequence = new Element(1327120, 'TransmitTransducerSequence', 'SQ', '1', '00144010', undefined)
exports.ReceiveTransducerSequence = new Element(1327121, 'ReceiveTransducerSequence', 'SQ', '1', '00144011', undefined)
exports.NumberOfElements = new Element(1327122, 'NumberOfElements', 'US', '1', '00144012', undefined)
exports.ElementShape = new Element(1327123, 'ElementShape', 'CS', '1', '00144013', undefined)
exports.ElementDimensionA = new Element(1327124, 'ElementDimensionA', 'DS', '1', '00144014', undefined)
exports.ElementDimensionB = new Element(1327125, 'ElementDimensionB', 'DS', '1', '00144015', undefined)
exports.ElementPitchA = new Element(1327126, 'ElementPitchA', 'DS', '1', '00144016', undefined)
exports.MeasuredBeamDimensionA = new Element(1327127, 'MeasuredBeamDimensionA', 'DS', '1', '00144017', undefined)
exports.MeasuredBeamDimensionB = new Element(1327128, 'MeasuredBeamDimensionB', 'DS', '1', '00144018', undefined)
exports.LocationOfMeasuredBeamDiameter = new Element(1327129, 'LocationOfMeasuredBeamDiameter', 'DS', '1', '00144019', undefined)
exports.NominalFrequency = new Element(1327130, 'NominalFrequency', 'DS', '1', '0014401A', undefined)
exports.MeasuredCenterFrequency = new Element(1327131, 'MeasuredCenterFrequency', 'DS', '1', '0014401B', undefined)
exports.MeasuredBandwidth = new Element(1327132, 'MeasuredBandwidth', 'DS', '1', '0014401C', undefined)
exports.ElementPitchB = new Element(1327133, 'ElementPitchB', 'DS', '1', '0014401D', undefined)
exports.PulserSettingsSequence = new Element(1327136, 'PulserSettingsSequence', 'SQ', '1', '00144020', undefined)
exports.PulseWidth = new Element(1327138, 'PulseWidth', 'DS', '1', '00144022', undefined)
exports.ExcitationFrequency = new Element(1327140, 'ExcitationFrequency', 'DS', '1', '00144024', undefined)
exports.ModulationType = new Element(1327142, 'ModulationType', 'CS', '1', '00144026', undefined)
exports.Damping = new Element(1327144, 'Damping', 'DS', '1', '00144028', undefined)
exports.ReceiverSettingsSequence = new Element(1327152, 'ReceiverSettingsSequence', 'SQ', '1', '00144030', undefined)
exports.AcquiredSoundpathLength = new Element(1327153, 'AcquiredSoundpathLength', 'DS', '1', '00144031', undefined)
exports.AcquisitionCompressionType = new Element(1327154, 'AcquisitionCompressionType', 'CS', '1', '00144032', undefined)
exports.AcquisitionSampleSize = new Element(1327155, 'AcquisitionSampleSize', 'IS', '1', '00144033', undefined)
exports.RectifierSmoothing = new Element(1327156, 'RectifierSmoothing', 'DS', '1', '00144034', undefined)
exports.DACSequence = new Element(1327157, 'DACSequence', 'SQ', '1', '00144035', undefined)
exports.DACType = new Element(1327158, 'DACType', 'CS', '1', '00144036', undefined)
exports.DACGainPoints = new Element(1327160, 'DACGainPoints', 'DS', '1-n', '00144038', undefined)
exports.DACTimePoints = new Element(1327162, 'DACTimePoints', 'DS', '1-n', '0014403A', undefined)
exports.DACAmplitude = new Element(1327164, 'DACAmplitude', 'DS', '1-n', '0014403C', undefined)
exports.PreAmplifierSettingsSequence = new Element(1327168, 'PreAmplifierSettingsSequence', 'SQ', '1', '00144040', undefined)
exports.TransmitTransducerSettingsSequence = new Element(1327184, 'TransmitTransducerSettingsSequence', 'SQ', '1', '00144050', undefined)
exports.ReceiveTransducerSettingsSequence = new Element(1327185, 'ReceiveTransducerSettingsSequence', 'SQ', '1', '00144051', undefined)
exports.IncidentAngle = new Element(1327186, 'IncidentAngle', 'DS', '1', '00144052', undefined)
exports.CouplingTechnique = new Element(1327188, 'CouplingTechnique', 'ST', '1', '00144054', undefined)
exports.CouplingMedium = new Element(1327190, 'CouplingMedium', 'ST', '1', '00144056', undefined)
exports.CouplingVelocity = new Element(1327191, 'CouplingVelocity', 'DS', '1', '00144057', undefined)
exports.ProbeCenterLocationX = new Element(1327192, 'ProbeCenterLocationX', 'DS', '1', '00144058', undefined)
exports.ProbeCenterLocationZ = new Element(1327193, 'ProbeCenterLocationZ', 'DS', '1', '00144059', undefined)
exports.SoundPathLength = new Element(1327194, 'SoundPathLength', 'DS', '1', '0014405A', undefined)
exports.DelayLawIdentifier = new Element(1327196, 'DelayLawIdentifier', 'ST', '1', '0014405C', undefined)
exports.GateSettingsSequence = new Element(1327200, 'GateSettingsSequence', 'SQ', '1', '00144060', undefined)
exports.GateThreshold = new Element(1327202, 'GateThreshold', 'DS', '1', '00144062', undefined)
exports.VelocityOfSound = new Element(1327204, 'VelocityOfSound', 'DS', '1', '00144064', undefined)
exports.CalibrationSettingsSequence = new Element(1327216, 'CalibrationSettingsSequence', 'SQ', '1', '00144070', undefined)
exports.CalibrationProcedure = new Element(1327218, 'CalibrationProcedure', 'ST', '1', '00144072', undefined)
exports.ProcedureVersion = new Element(1327220, 'ProcedureVersion', 'SH', '1', '00144074', undefined)
exports.ProcedureCreationDate = new Element(1327222, 'ProcedureCreationDate', 'DA', '1', '00144076', undefined)
exports.ProcedureExpirationDate = new Element(1327224, 'ProcedureExpirationDate', 'DA', '1', '00144078', undefined)
exports.ProcedureLastModifiedDate = new Element(1327226, 'ProcedureLastModifiedDate', 'DA', '1', '0014407A', undefined)
exports.CalibrationTime = new Element(1327228, 'CalibrationTime', 'TM', '1-n', '0014407C', undefined)
exports.CalibrationDate = new Element(1327230, 'CalibrationDate', 'DA', '1-n', '0014407E', undefined)
exports.ProbeDriveEquipmentSequence = new Element(1327232, 'ProbeDriveEquipmentSequence', 'SQ', '1', '00144080', undefined)
exports.DriveType = new Element(1327233, 'DriveType', 'CS', '1', '00144081', undefined)
exports.ProbeDriveNotes = new Element(1327234, 'ProbeDriveNotes', 'LT', '1', '00144082', undefined)
exports.DriveProbeSequence = new Element(1327235, 'DriveProbeSequence', 'SQ', '1', '00144083', undefined)
exports.ProbeInductance = new Element(1327236, 'ProbeInductance', 'DS', '1', '00144084', undefined)
exports.ProbeResistance = new Element(1327237, 'ProbeResistance', 'DS', '1', '00144085', undefined)
exports.ReceiveProbeSequence = new Element(1327238, 'ReceiveProbeSequence', 'SQ', '1', '00144086', undefined)
exports.ProbeDriveSettingsSequence = new Element(1327239, 'ProbeDriveSettingsSequence', 'SQ', '1', '00144087', undefined)
exports.BridgeResistors = new Element(1327240, 'BridgeResistors', 'DS', '1', '00144088', undefined)
exports.ProbeOrientationAngle = new Element(1327241, 'ProbeOrientationAngle', 'DS', '1', '00144089', undefined)
exports.UserSelectedGainY = new Element(1327243, 'UserSelectedGainY', 'DS', '1', '0014408B', undefined)
exports.UserSelectedPhase = new Element(1327244, 'UserSelectedPhase', 'DS', '1', '0014408C', undefined)
exports.UserSelectedOffsetX = new Element(1327245, 'UserSelectedOffsetX', 'DS', '1', '0014408D', undefined)
exports.UserSelectedOffsetY = new Element(1327246, 'UserSelectedOffsetY', 'DS', '1', '0014408E', undefined)
exports.ChannelSettingsSequence = new Element(1327249, 'ChannelSettingsSequence', 'SQ', '1', '00144091', undefined)
exports.ChannelThreshold = new Element(1327250, 'ChannelThreshold', 'DS', '1', '00144092', undefined)
exports.ScannerSettingsSequence = new Element(1327258, 'ScannerSettingsSequence', 'SQ', '1', '0014409A', undefined)
exports.ScanProcedure = new Element(1327259, 'ScanProcedure', 'ST', '1', '0014409B', undefined)
exports.TranslationRateX = new Element(1327260, 'TranslationRateX', 'DS', '1', '0014409C', undefined)
exports.TranslationRateY = new Element(1327261, 'TranslationRateY', 'DS', '1', '0014409D', undefined)
exports.ChannelOverlap = new Element(1327263, 'ChannelOverlap', 'DS', '1', '0014409F', undefined)
exports.ImageQualityIndicatorType = new Element(1327264, 'ImageQualityIndicatorType', 'LO', '1', '001440A0', undefined)
exports.ImageQualityIndicatorMaterial = new Element(1327265, 'ImageQualityIndicatorMaterial', 'LO', '1', '001440A1', undefined)
exports.ImageQualityIndicatorSize = new Element(1327266, 'ImageQualityIndicatorSize', 'LO', '1', '001440A2', undefined)
exports.LINACEnergy = new Element(1331202, 'LINACEnergy', 'IS', '1', '00145002', undefined)
exports.LINACOutput = new Element(1331204, 'LINACOutput', 'IS', '1', '00145004', undefined)
exports.ContrastBolusAgent = new Element(1572880, 'ContrastBolusAgent', 'LO', '1', '00180010', undefined)
exports.ContrastBolusAgentSequence = new Element(1572882, 'ContrastBolusAgentSequence', 'SQ', '1', '00180012', undefined)
exports.ContrastBolusT1Relaxivity = new Element(1572883, 'ContrastBolusT1Relaxivity', 'FL', '1', '00180013', undefined)
exports.ContrastBolusAdministrationRouteSequence = new Element(1572884, 'ContrastBolusAdministrationRouteSequence', 'SQ', '1', '00180014', undefined)
exports.BodyPartExamined = new Element(1572885, 'BodyPartExamined', 'CS', '1', '00180015', undefined)
exports.ScanningSequence = new Element(1572896, 'ScanningSequence', 'CS', '1-n', '00180020', undefined)
exports.SequenceVariant = new Element(1572897, 'SequenceVariant', 'CS', '1-n', '00180021', undefined)
exports.ScanOptions = new Element(1572898, 'ScanOptions', 'CS', '1-n', '00180022', undefined)
exports.MRAcquisitionType = new Element(1572899, 'MRAcquisitionType', 'CS', '1', '00180023', undefined)
exports.SequenceName = new Element(1572900, 'SequenceName', 'SH', '1', '00180024', undefined)
exports.AngioFlag = new Element(1572901, 'AngioFlag', 'CS', '1', '00180025', undefined)
exports.InterventionDrugInformationSequence = new Element(1572902, 'InterventionDrugInformationSequence', 'SQ', '1', '00180026', undefined)
exports.InterventionDrugStopTime = new Element(1572903, 'InterventionDrugStopTime', 'TM', '1', '00180027', undefined)
exports.InterventionDrugDose = new Element(1572904, 'InterventionDrugDose', 'DS', '1', '00180028', undefined)
exports.InterventionDrugCodeSequence = new Element(1572905, 'InterventionDrugCodeSequence', 'SQ', '1', '00180029', undefined)
exports.AdditionalDrugSequence = new Element(1572906, 'AdditionalDrugSequence', 'SQ', '1', '0018002A', undefined)
exports.Radionuclide = new Element(1572912, 'Radionuclide', 'LO', '1-n', '00180030', true)
exports.Radiopharmaceutical = new Element(1572913, 'Radiopharmaceutical', 'LO', '1', '00180031', undefined)
exports.EnergyWindowCenterline = new Element(1572914, 'EnergyWindowCenterline', 'DS', '1', '00180032', true)
exports.EnergyWindowTotalWidth = new Element(1572915, 'EnergyWindowTotalWidth', 'DS', '1-n', '00180033', true)
exports.InterventionDrugName = new Element(1572916, 'InterventionDrugName', 'LO', '1', '00180034', undefined)
exports.InterventionDrugStartTime = new Element(1572917, 'InterventionDrugStartTime', 'TM', '1', '00180035', undefined)
exports.InterventionSequence = new Element(1572918, 'InterventionSequence', 'SQ', '1', '00180036', undefined)
exports.TherapyType = new Element(1572919, 'TherapyType', 'CS', '1', '00180037', true)
exports.InterventionStatus = new Element(1572920, 'InterventionStatus', 'CS', '1', '00180038', undefined)
exports.TherapyDescription = new Element(1572921, 'TherapyDescription', 'CS', '1', '00180039', true)
exports.InterventionDescription = new Element(1572922, 'InterventionDescription', 'ST', '1', '0018003A', undefined)
exports.CineRate = new Element(1572928, 'CineRate', 'IS', '1', '00180040', undefined)
exports.InitialCineRunState = new Element(1572930, 'InitialCineRunState', 'CS', '1', '00180042', undefined)
exports.SliceThickness = new Element(1572944, 'SliceThickness', 'DS', '1', '00180050', undefined)
exports.KVP = new Element(1572960, 'KVP', 'DS', '1', '00180060', undefined)
exports.CountsAccumulated = new Element(1572976, 'CountsAccumulated', 'IS', '1', '00180070', undefined)
exports.AcquisitionTerminationCondition = new Element(1572977, 'AcquisitionTerminationCondition', 'CS', '1', '00180071', undefined)
exports.EffectiveDuration = new Element(1572978, 'EffectiveDuration', 'DS', '1', '00180072', undefined)
exports.AcquisitionStartCondition = new Element(1572979, 'AcquisitionStartCondition', 'CS', '1', '00180073', undefined)
exports.AcquisitionStartConditionData = new Element(1572980, 'AcquisitionStartConditionData', 'IS', '1', '00180074', undefined)
exports.AcquisitionTerminationConditionData = new Element(1572981, 'AcquisitionTerminationConditionData', 'IS', '1', '00180075', undefined)
exports.RepetitionTime = new Element(1572992, 'RepetitionTime', 'DS', '1', '00180080', undefined)
exports.EchoTime = new Element(1572993, 'EchoTime', 'DS', '1', '00180081', undefined)
exports.InversionTime = new Element(1572994, 'InversionTime', 'DS', '1', '00180082', undefined)
exports.NumberOfAverages = new Element(1572995, 'NumberOfAverages', 'DS', '1', '00180083', undefined)
exports.ImagingFrequency = new Element(1572996, 'ImagingFrequency', 'DS', '1', '00180084', undefined)
exports.ImagedNucleus = new Element(1572997, 'ImagedNucleus', 'SH', '1', '00180085', undefined)
exports.EchoNumbers = new Element(1572998, 'EchoNumbers', 'IS', '1-n', '00180086', undefined)
exports.MagneticFieldStrength = new Element(1572999, 'MagneticFieldStrength', 'DS', '1', '00180087', undefined)
exports.SpacingBetweenSlices = new Element(1573000, 'SpacingBetweenSlices', 'DS', '1', '00180088', undefined)
exports.NumberOfPhaseEncodingSteps = new Element(1573001, 'NumberOfPhaseEncodingSteps', 'IS', '1', '00180089', undefined)
exports.DataCollectionDiameter = new Element(1573008, 'DataCollectionDiameter', 'DS', '1', '00180090', undefined)
exports.EchoTrainLength = new Element(1573009, 'EchoTrainLength', 'IS', '1', '00180091', undefined)
exports.PercentSampling = new Element(1573011, 'PercentSampling', 'DS', '1', '00180093', undefined)
exports.PercentPhaseFieldOfView = new Element(1573012, 'PercentPhaseFieldOfView', 'DS', '1', '00180094', undefined)
exports.PixelBandwidth = new Element(1573013, 'PixelBandwidth', 'DS', '1', '00180095', undefined)
exports.DeviceSerialNumber = new Element(1576960, 'DeviceSerialNumber', 'LO', '1', '00181000', undefined)
exports.DeviceUID = new Element(1576962, 'DeviceUID', 'UI', '1', '00181002', undefined)
exports.DeviceID = new Element(1576963, 'DeviceID', 'LO', '1', '00181003', undefined)
exports.PlateID = new Element(1576964, 'PlateID', 'LO', '1', '00181004', undefined)
exports.GeneratorID = new Element(1576965, 'GeneratorID', 'LO', '1', '00181005', undefined)
exports.GridID = new Element(1576966, 'GridID', 'LO', '1', '00181006', undefined)
exports.CassetteID = new Element(1576967, 'CassetteID', 'LO', '1', '00181007', undefined)
exports.GantryID = new Element(1576968, 'GantryID', 'LO', '1', '00181008', undefined)
exports.SecondaryCaptureDeviceID = new Element(1576976, 'SecondaryCaptureDeviceID', 'LO', '1', '00181010', undefined)
exports.HardcopyCreationDeviceID = new Element(1576977, 'HardcopyCreationDeviceID', 'LO', '1', '00181011', true)
exports.DateOfSecondaryCapture = new Element(1576978, 'DateOfSecondaryCapture', 'DA', '1', '00181012', undefined)
exports.TimeOfSecondaryCapture = new Element(1576980, 'TimeOfSecondaryCapture', 'TM', '1', '00181014', undefined)
exports.SecondaryCaptureDeviceManufacturer = new Element(1576982, 'SecondaryCaptureDeviceManufacturer', 'LO', '1', '00181016', undefined)
exports.HardcopyDeviceManufacturer = new Element(1576983, 'HardcopyDeviceManufacturer', 'LO', '1', '00181017', true)
exports.SecondaryCaptureDeviceManufacturerModelName = new Element(1576984, 'SecondaryCaptureDeviceManufacturerModelName', 'LO', '1', '00181018', undefined)
exports.SecondaryCaptureDeviceSoftwareVersions = new Element(1576985, 'SecondaryCaptureDeviceSoftwareVersions', 'LO', '1-n', '00181019', undefined)
exports.HardcopyDeviceSoftwareVersion = new Element(1576986, 'HardcopyDeviceSoftwareVersion', 'LO', '1-n', '0018101A', true)
exports.HardcopyDeviceManufacturerModelName = new Element(1576987, 'HardcopyDeviceManufacturerModelName', 'LO', '1', '0018101B', true)
exports.SoftwareVersions = new Element(1576992, 'SoftwareVersions', 'LO', '1-n', '00181020', undefined)
exports.VideoImageFormatAcquired = new Element(1576994, 'VideoImageFormatAcquired', 'SH', '1', '00181022', undefined)
exports.DigitalImageFormatAcquired = new Element(1576995, 'DigitalImageFormatAcquired', 'LO', '1', '00181023', undefined)
exports.ProtocolName = new Element(1577008, 'ProtocolName', 'LO', '1', '00181030', undefined)
exports.ContrastBolusRoute = new Element(1577024, 'ContrastBolusRoute', 'LO', '1', '00181040', undefined)
exports.ContrastBolusVolume = new Element(1577025, 'ContrastBolusVolume', 'DS', '1', '00181041', undefined)
exports.ContrastBolusStartTime = new Element(1577026, 'ContrastBolusStartTime', 'TM', '1', '00181042', undefined)
exports.ContrastBolusStopTime = new Element(1577027, 'ContrastBolusStopTime', 'TM', '1', '00181043', undefined)
exports.ContrastBolusTotalDose = new Element(1577028, 'ContrastBolusTotalDose', 'DS', '1', '00181044', undefined)
exports.SyringeCounts = new Element(1577029, 'SyringeCounts', 'IS', '1', '00181045', undefined)
exports.ContrastFlowRate = new Element(1577030, 'ContrastFlowRate', 'DS', '1-n', '00181046', undefined)
exports.ContrastFlowDuration = new Element(1577031, 'ContrastFlowDuration', 'DS', '1-n', '00181047', undefined)
exports.ContrastBolusIngredient = new Element(1577032, 'ContrastBolusIngredient', 'CS', '1', '00181048', undefined)
exports.ContrastBolusIngredientConcentration = new Element(1577033, 'ContrastBolusIngredientConcentration', 'DS', '1', '00181049', undefined)
exports.SpatialResolution = new Element(1577040, 'SpatialResolution', 'DS', '1', '00181050', undefined)
exports.TriggerTime = new Element(1577056, 'TriggerTime', 'DS', '1', '00181060', undefined)
exports.TriggerSourceOrType = new Element(1577057, 'TriggerSourceOrType', 'LO', '1', '00181061', undefined)
exports.NominalInterval = new Element(1577058, 'NominalInterval', 'IS', '1', '00181062', undefined)
exports.FrameTime = new Element(1577059, 'FrameTime', 'DS', '1', '00181063', undefined)
exports.CardiacFramingType = new Element(1577060, 'CardiacFramingType', 'LO', '1', '00181064', undefined)
exports.FrameTimeVector = new Element(1577061, 'FrameTimeVector', 'DS', '1-n', '00181065', undefined)
exports.FrameDelay = new Element(1577062, 'FrameDelay', 'DS', '1', '00181066', undefined)
exports.ImageTriggerDelay = new Element(1577063, 'ImageTriggerDelay', 'DS', '1', '00181067', undefined)
exports.MultiplexGroupTimeOffset = new Element(1577064, 'MultiplexGroupTimeOffset', 'DS', '1', '00181068', undefined)
exports.TriggerTimeOffset = new Element(1577065, 'TriggerTimeOffset', 'DS', '1', '00181069', undefined)
exports.SynchronizationTrigger = new Element(1577066, 'SynchronizationTrigger', 'CS', '1', '0018106A', undefined)
exports.SynchronizationChannel = new Element(1577068, 'SynchronizationChannel', 'US', '2', '0018106C', undefined)
exports.TriggerSamplePosition = new Element(1577070, 'TriggerSamplePosition', 'UL', '1', '0018106E', undefined)
exports.RadiopharmaceuticalRoute = new Element(1577072, 'RadiopharmaceuticalRoute', 'LO', '1', '00181070', undefined)
exports.RadiopharmaceuticalVolume = new Element(1577073, 'RadiopharmaceuticalVolume', 'DS', '1', '00181071', undefined)
exports.RadiopharmaceuticalStartTime = new Element(1577074, 'RadiopharmaceuticalStartTime', 'TM', '1', '00181072', undefined)
exports.RadiopharmaceuticalStopTime = new Element(1577075, 'RadiopharmaceuticalStopTime', 'TM', '1', '00181073', undefined)
exports.RadionuclideTotalDose = new Element(1577076, 'RadionuclideTotalDose', 'DS', '1', '00181074', undefined)
exports.RadionuclideHalfLife = new Element(1577077, 'RadionuclideHalfLife', 'DS', '1', '00181075', undefined)
exports.RadionuclidePositronFraction = new Element(1577078, 'RadionuclidePositronFraction', 'DS', '1', '00181076', undefined)
exports.RadiopharmaceuticalSpecificActivity = new Element(1577079, 'RadiopharmaceuticalSpecificActivity', 'DS', '1', '00181077', undefined)
exports.RadiopharmaceuticalStartDateTime = new Element(1577080, 'RadiopharmaceuticalStartDateTime', 'DT', '1', '00181078', undefined)
exports.RadiopharmaceuticalStopDateTime = new Element(1577081, 'RadiopharmaceuticalStopDateTime', 'DT', '1', '00181079', undefined)
exports.BeatRejectionFlag = new Element(1577088, 'BeatRejectionFlag', 'CS', '1', '00181080', undefined)
exports.LowRRValue = new Element(1577089, 'LowRRValue', 'IS', '1', '00181081', undefined)
exports.HighRRValue = new Element(1577090, 'HighRRValue', 'IS', '1', '00181082', undefined)
exports.IntervalsAcquired = new Element(1577091, 'IntervalsAcquired', 'IS', '1', '00181083', undefined)
exports.IntervalsRejected = new Element(1577092, 'IntervalsRejected', 'IS', '1', '00181084', undefined)
exports.PVCRejection = new Element(1577093, 'PVCRejection', 'LO', '1', '00181085', undefined)
exports.SkipBeats = new Element(1577094, 'SkipBeats', 'IS', '1', '00181086', undefined)
exports.HeartRate = new Element(1577096, 'HeartRate', 'IS', '1', '00181088', undefined)
exports.CardiacNumberOfImages = new Element(1577104, 'CardiacNumberOfImages', 'IS', '1', '00181090', undefined)
exports.TriggerWindow = new Element(1577108, 'TriggerWindow', 'IS', '1', '00181094', undefined)
exports.ReconstructionDiameter = new Element(1577216, 'ReconstructionDiameter', 'DS', '1', '00181100', undefined)
exports.DistanceSourceToDetector = new Element(1577232, 'DistanceSourceToDetector', 'DS', '1', '00181110', undefined)
exports.DistanceSourceToPatient = new Element(1577233, 'DistanceSourceToPatient', 'DS', '1', '00181111', undefined)
exports.EstimatedRadiographicMagnificationFactor = new Element(1577236, 'EstimatedRadiographicMagnificationFactor', 'DS', '1', '00181114', undefined)
exports.GantryDetectorTilt = new Element(1577248, 'GantryDetectorTilt', 'DS', '1', '00181120', undefined)
exports.GantryDetectorSlew = new Element(1577249, 'GantryDetectorSlew', 'DS', '1', '00181121', undefined)
exports.TableHeight = new Element(1577264, 'TableHeight', 'DS', '1', '00181130', undefined)
exports.TableTraverse = new Element(1577265, 'TableTraverse', 'DS', '1', '00181131', undefined)
exports.TableMotion = new Element(1577268, 'TableMotion', 'CS', '1', '00181134', undefined)
exports.TableVerticalIncrement = new Element(1577269, 'TableVerticalIncrement', 'DS', '1-n', '00181135', undefined)
exports.TableLateralIncrement = new Element(1577270, 'TableLateralIncrement', 'DS', '1-n', '00181136', undefined)
exports.TableLongitudinalIncrement = new Element(1577271, 'TableLongitudinalIncrement', 'DS', '1-n', '00181137', undefined)
exports.TableAngle = new Element(1577272, 'TableAngle', 'DS', '1', '00181138', undefined)
exports.TableType = new Element(1577274, 'TableType', 'CS', '1', '0018113A', undefined)
exports.RotationDirection = new Element(1577280, 'RotationDirection', 'CS', '1', '00181140', undefined)
exports.AngularPosition = new Element(1577281, 'AngularPosition', 'DS', '1', '00181141', true)
exports.RadialPosition = new Element(1577282, 'RadialPosition', 'DS', '1-n', '00181142', undefined)
exports.ScanArc = new Element(1577283, 'ScanArc', 'DS', '1', '00181143', undefined)
exports.AngularStep = new Element(1577284, 'AngularStep', 'DS', '1', '00181144', undefined)
exports.CenterOfRotationOffset = new Element(1577285, 'CenterOfRotationOffset', 'DS', '1', '00181145', undefined)
exports.RotationOffset = new Element(1577286, 'RotationOffset', 'DS', '1-n', '00181146', true)
exports.FieldOfViewShape = new Element(1577287, 'FieldOfViewShape', 'CS', '1', '00181147', undefined)
exports.FieldOfViewDimensions = new Element(1577289, 'FieldOfViewDimensions', 'IS', '1-2', '00181149', undefined)
exports.ExposureTime = new Element(1577296, 'ExposureTime', 'IS', '1', '00181150', undefined)
exports.XRayTubeCurrent = new Element(1577297, 'XRayTubeCurrent', 'IS', '1', '00181151', undefined)
exports.Exposure = new Element(1577298, 'Exposure', 'IS', '1', '00181152', undefined)
exports.ExposureInuAs = new Element(1577299, 'ExposureInuAs', 'IS', '1', '00181153', undefined)
exports.AveragePulseWidth = new Element(1577300, 'AveragePulseWidth', 'DS', '1', '00181154', undefined)
exports.RadiationSetting = new Element(1577301, 'RadiationSetting', 'CS', '1', '00181155', undefined)
exports.RectificationType = new Element(1577302, 'RectificationType', 'CS', '1', '00181156', undefined)
exports.RadiationMode = new Element(1577306, 'RadiationMode', 'CS', '1', '0018115A', undefined)
exports.ImageAndFluoroscopyAreaDoseProduct = new Element(1577310, 'ImageAndFluoroscopyAreaDoseProduct', 'DS', '1', '0018115E', undefined)
exports.FilterType = new Element(1577312, 'FilterType', 'SH', '1', '00181160', undefined)
exports.TypeOfFilters = new Element(1577313, 'TypeOfFilters', 'LO', '1-n', '00181161', undefined)
exports.IntensifierSize = new Element(1577314, 'IntensifierSize', 'DS', '1', '00181162', undefined)
exports.ImagerPixelSpacing = new Element(1577316, 'ImagerPixelSpacing', 'DS', '2', '00181164', undefined)
exports.Grid = new Element(1577318, 'Grid', 'CS', '1-n', '00181166', undefined)
exports.GeneratorPower = new Element(1577328, 'GeneratorPower', 'IS', '1', '00181170', undefined)
exports.CollimatorGridName = new Element(1577344, 'CollimatorGridName', 'SH', '1', '00181180', undefined)
exports.CollimatorType = new Element(1577345, 'CollimatorType', 'CS', '1', '00181181', undefined)
exports.FocalDistance = new Element(1577346, 'FocalDistance', 'IS', '1-2', '00181182', undefined)
exports.XFocusCenter = new Element(1577347, 'XFocusCenter', 'DS', '1-2', '00181183', undefined)
exports.YFocusCenter = new Element(1577348, 'YFocusCenter', 'DS', '1-2', '00181184', undefined)
exports.FocalSpots = new Element(1577360, 'FocalSpots', 'DS', '1-n', '00181190', undefined)
exports.AnodeTargetMaterial = new Element(1577361, 'AnodeTargetMaterial', 'CS', '1', '00181191', undefined)
exports.BodyPartThickness = new Element(1577376, 'BodyPartThickness', 'DS', '1', '001811A0', undefined)
exports.CompressionForce = new Element(1577378, 'CompressionForce', 'DS', '1', '001811A2', undefined)
exports.PaddleDescription = new Element(1577380, 'PaddleDescription', 'LO', '1', '001811A4', undefined)
exports.DateOfLastCalibration = new Element(1577472, 'DateOfLastCalibration', 'DA', '1-n', '00181200', undefined)
exports.TimeOfLastCalibration = new Element(1577473, 'TimeOfLastCalibration', 'TM', '1-n', '00181201', undefined)
exports.DateTimeOfLastCalibration = new Element(1577474, 'DateTimeOfLastCalibration', 'DT', '1', '00181202', undefined)
exports.ConvolutionKernel = new Element(1577488, 'ConvolutionKernel', 'SH', '1-n', '00181210', undefined)
exports.UpperLowerPixelValues = new Element(1577536, 'UpperLowerPixelValues', 'IS', '1-n', '00181240', true)
exports.ActualFrameDuration = new Element(1577538, 'ActualFrameDuration', 'IS', '1', '00181242', undefined)
exports.CountRate = new Element(1577539, 'CountRate', 'IS', '1', '00181243', undefined)
exports.PreferredPlaybackSequencing = new Element(1577540, 'PreferredPlaybackSequencing', 'US', '1', '00181244', undefined)
exports.ReceiveCoilName = new Element(1577552, 'ReceiveCoilName', 'SH', '1', '00181250', undefined)
exports.TransmitCoilName = new Element(1577553, 'TransmitCoilName', 'SH', '1', '00181251', undefined)
exports.PlateType = new Element(1577568, 'PlateType', 'SH', '1', '00181260', undefined)
exports.PhosphorType = new Element(1577569, 'PhosphorType', 'LO', '1', '00181261', undefined)
exports.ScanVelocity = new Element(1577728, 'ScanVelocity', 'DS', '1', '00181300', undefined)
exports.WholeBodyTechnique = new Element(1577729, 'WholeBodyTechnique', 'CS', '1-n', '00181301', undefined)
exports.ScanLength = new Element(1577730, 'ScanLength', 'IS', '1', '00181302', undefined)
exports.AcquisitionMatrix = new Element(1577744, 'AcquisitionMatrix', 'US', '4', '00181310', undefined)
exports.InPlanePhaseEncodingDirection = new Element(1577746, 'InPlanePhaseEncodingDirection', 'CS', '1', '00181312', undefined)
exports.FlipAngle = new Element(1577748, 'FlipAngle', 'DS', '1', '00181314', undefined)
exports.VariableFlipAngleFlag = new Element(1577749, 'VariableFlipAngleFlag', 'CS', '1', '00181315', undefined)
exports.SAR = new Element(1577750, 'SAR', 'DS', '1', '00181316', undefined)
exports.dBdt = new Element(1577752, 'dBdt', 'DS', '1', '00181318', undefined)
exports.AcquisitionDeviceProcessingDescription = new Element(1577984, 'AcquisitionDeviceProcessingDescription', 'LO', '1', '00181400', undefined)
exports.AcquisitionDeviceProcessingCode = new Element(1577985, 'AcquisitionDeviceProcessingCode', 'LO', '1', '00181401', undefined)
exports.CassetteOrientation = new Element(1577986, 'CassetteOrientation', 'CS', '1', '00181402', undefined)
exports.CassetteSize = new Element(1577987, 'CassetteSize', 'CS', '1', '00181403', undefined)
exports.ExposuresOnPlate = new Element(1577988, 'ExposuresOnPlate', 'US', '1', '00181404', undefined)
exports.RelativeXRayExposure = new Element(1577989, 'RelativeXRayExposure', 'IS', '1', '00181405', undefined)
exports.ExposureIndex = new Element(1578001, 'ExposureIndex', 'DS', '1', '00181411', undefined)
exports.TargetExposureIndex = new Element(1578002, 'TargetExposureIndex', 'DS', '1', '00181412', undefined)
exports.DeviationIndex = new Element(1578003, 'DeviationIndex', 'DS', '1', '00181413', undefined)
exports.ColumnAngulation = new Element(1578064, 'ColumnAngulation', 'DS', '1', '00181450', undefined)
exports.TomoLayerHeight = new Element(1578080, 'TomoLayerHeight', 'DS', '1', '00181460', undefined)
exports.TomoAngle = new Element(1578096, 'TomoAngle', 'DS', '1', '00181470', undefined)
exports.TomoTime = new Element(1578112, 'TomoTime', 'DS', '1', '00181480', undefined)
exports.TomoType = new Element(1578128, 'TomoType', 'CS', '1', '00181490', undefined)
exports.TomoClass = new Element(1578129, 'TomoClass', 'CS', '1', '00181491', undefined)
exports.NumberOfTomosynthesisSourceImages = new Element(1578133, 'NumberOfTomosynthesisSourceImages', 'IS', '1', '00181495', undefined)
exports.PositionerMotion = new Element(1578240, 'PositionerMotion', 'CS', '1', '00181500', undefined)
exports.PositionerType = new Element(1578248, 'PositionerType', 'CS', '1', '00181508', undefined)
exports.PositionerPrimaryAngle = new Element(1578256, 'PositionerPrimaryAngle', 'DS', '1', '00181510', undefined)
exports.PositionerSecondaryAngle = new Element(1578257, 'PositionerSecondaryAngle', 'DS', '1', '00181511', undefined)
exports.PositionerPrimaryAngleIncrement = new Element(1578272, 'PositionerPrimaryAngleIncrement', 'DS', '1-n', '00181520', undefined)
exports.PositionerSecondaryAngleIncrement = new Element(1578273, 'PositionerSecondaryAngleIncrement', 'DS', '1-n', '00181521', undefined)
exports.DetectorPrimaryAngle = new Element(1578288, 'DetectorPrimaryAngle', 'DS', '1', '00181530', undefined)
exports.DetectorSecondaryAngle = new Element(1578289, 'DetectorSecondaryAngle', 'DS', '1', '00181531', undefined)
exports.ShutterShape = new Element(1578496, 'ShutterShape', 'CS', '1-3', '00181600', undefined)
exports.ShutterLeftVerticalEdge = new Element(1578498, 'ShutterLeftVerticalEdge', 'IS', '1', '00181602', undefined)
exports.ShutterRightVerticalEdge = new Element(1578500, 'ShutterRightVerticalEdge', 'IS', '1', '00181604', undefined)
exports.ShutterUpperHorizontalEdge = new Element(1578502, 'ShutterUpperHorizontalEdge', 'IS', '1', '00181606', undefined)
exports.ShutterLowerHorizontalEdge = new Element(1578504, 'ShutterLowerHorizontalEdge', 'IS', '1', '00181608', undefined)
exports.CenterOfCircularShutter = new Element(1578512, 'CenterOfCircularShutter', 'IS', '2', '00181610', undefined)
exports.RadiusOfCircularShutter = new Element(1578514, 'RadiusOfCircularShutter', 'IS', '1', '00181612', undefined)
exports.VerticesOfThePolygonalShutter = new Element(1578528, 'VerticesOfThePolygonalShutter', 'IS', '2-2n', '00181620', undefined)
exports.ShutterPresentationValue = new Element(1578530, 'ShutterPresentationValue', 'US', '1', '00181622', undefined)
exports.ShutterOverlayGroup = new Element(1578531, 'ShutterOverlayGroup', 'US', '1', '00181623', undefined)
exports.ShutterPresentationColorCIELabValue = new Element(1578532, 'ShutterPresentationColorCIELabValue', 'US', '3', '00181624', undefined)
exports.CollimatorShape = new Element(1578752, 'CollimatorShape', 'CS', '1-3', '00181700', undefined)
exports.CollimatorLeftVerticalEdge = new Element(1578754, 'CollimatorLeftVerticalEdge', 'IS', '1', '00181702', undefined)
exports.CollimatorRightVerticalEdge = new Element(1578756, 'CollimatorRightVerticalEdge', 'IS', '1', '00181704', undefined)
exports.CollimatorUpperHorizontalEdge = new Element(1578758, 'CollimatorUpperHorizontalEdge', 'IS', '1', '00181706', undefined)
exports.CollimatorLowerHorizontalEdge = new Element(1578760, 'CollimatorLowerHorizontalEdge', 'IS', '1', '00181708', undefined)
exports.CenterOfCircularCollimator = new Element(1578768, 'CenterOfCircularCollimator', 'IS', '2', '00181710', undefined)
exports.RadiusOfCircularCollimator = new Element(1578770, 'RadiusOfCircularCollimator', 'IS', '1', '00181712', undefined)
exports.VerticesOfThePolygonalCollimator = new Element(1578784, 'VerticesOfThePolygonalCollimator', 'IS', '2-2n', '00181720', undefined)
exports.AcquisitionTimeSynchronized = new Element(1579008, 'AcquisitionTimeSynchronized', 'CS', '1', '00181800', undefined)
exports.TimeSource = new Element(1579009, 'TimeSource', 'SH', '1', '00181801', undefined)
exports.TimeDistributionProtocol = new Element(1579010, 'TimeDistributionProtocol', 'CS', '1', '00181802', undefined)
exports.NTPSourceAddress = new Element(1579011, 'NTPSourceAddress', 'LO', '1', '00181803', undefined)
exports.PageNumberVector = new Element(1581057, 'PageNumberVector', 'IS', '1-n', '00182001', undefined)
exports.FrameLabelVector = new Element(1581058, 'FrameLabelVector', 'SH', '1-n', '00182002', undefined)
exports.FramePrimaryAngleVector = new Element(1581059, 'FramePrimaryAngleVector', 'DS', '1-n', '00182003', undefined)
exports.FrameSecondaryAngleVector = new Element(1581060, 'FrameSecondaryAngleVector', 'DS', '1-n', '00182004', undefined)
exports.SliceLocationVector = new Element(1581061, 'SliceLocationVector', 'DS', '1-n', '00182005', undefined)
exports.DisplayWindowLabelVector = new Element(1581062, 'DisplayWindowLabelVector', 'SH', '1-n', '00182006', undefined)
exports.NominalScannedPixelSpacing = new Element(1581072, 'NominalScannedPixelSpacing', 'DS', '2', '00182010', undefined)
exports.DigitizingDeviceTransportDirection = new Element(1581088, 'DigitizingDeviceTransportDirection', 'CS', '1', '00182020', undefined)
exports.RotationOfScannedFilm = new Element(1581104, 'RotationOfScannedFilm', 'DS', '1', '00182030', undefined)
exports.BiopsyTargetSequence = new Element(1581121, 'BiopsyTargetSequence', 'SQ', '1', '00182041', undefined)
exports.TargetUID = new Element(1581122, 'TargetUID', 'UI', '1', '00182042', undefined)
exports.LocalizingCursorPosition = new Element(1581123, 'LocalizingCursorPosition', 'FL', '2', '00182043', undefined)
exports.CalculatedTargetPosition = new Element(1581124, 'CalculatedTargetPosition', 'FL', '3', '00182044', undefined)
exports.TargetLabel = new Element(1581125, 'TargetLabel', 'SH', '1', '00182045', undefined)
exports.DisplayedZValue = new Element(1581126, 'DisplayedZValue', 'FL', '1', '00182046', undefined)
exports.IVUSAcquisition = new Element(1585408, 'IVUSAcquisition', 'CS', '1', '00183100', undefined)
exports.IVUSPullbackRate = new Element(1585409, 'IVUSPullbackRate', 'DS', '1', '00183101', undefined)
exports.IVUSGatedRate = new Element(1585410, 'IVUSGatedRate', 'DS', '1', '00183102', undefined)
exports.IVUSPullbackStartFrameNumber = new Element(1585411, 'IVUSPullbackStartFrameNumber', 'IS', '1', '00183103', undefined)
exports.IVUSPullbackStopFrameNumber = new Element(1585412, 'IVUSPullbackStopFrameNumber', 'IS', '1', '00183104', undefined)
exports.LesionNumber = new Element(1585413, 'LesionNumber', 'IS', '1-n', '00183105', undefined)
exports.AcquisitionComments = new Element(1589248, 'AcquisitionComments', 'LT', '1', '00184000', true)
exports.OutputPower = new Element(1593344, 'OutputPower', 'SH', '1-n', '00185000', undefined)
exports.TransducerData = new Element(1593360, 'TransducerData', 'LO', '1-n', '00185010', undefined)
exports.FocusDepth = new Element(1593362, 'FocusDepth', 'DS', '1', '00185012', undefined)
exports.ProcessingFunction = new Element(1593376, 'ProcessingFunction', 'LO', '1', '00185020', undefined)
exports.PostprocessingFunction = new Element(1593377, 'PostprocessingFunction', 'LO', '1', '00185021', true)
exports.MechanicalIndex = new Element(1593378, 'MechanicalIndex', 'DS', '1', '00185022', undefined)
exports.BoneThermalIndex = new Element(1593380, 'BoneThermalIndex', 'DS', '1', '00185024', undefined)
exports.CranialThermalIndex = new Element(1593382, 'CranialThermalIndex', 'DS', '1', '00185026', undefined)
exports.SoftTissueThermalIndex = new Element(1593383, 'SoftTissueThermalIndex', 'DS', '1', '00185027', undefined)
exports.SoftTissueFocusThermalIndex = new Element(1593384, 'SoftTissueFocusThermalIndex', 'DS', '1', '00185028', undefined)
exports.SoftTissueSurfaceThermalIndex = new Element(1593385, 'SoftTissueSurfaceThermalIndex', 'DS', '1', '00185029', undefined)
exports.DynamicRange = new Element(1593392, 'DynamicRange', 'DS', '1', '00185030', true)
exports.TotalGain = new Element(1593408, 'TotalGain', 'DS', '1', '00185040', true)
exports.DepthOfScanField = new Element(1593424, 'DepthOfScanField', 'IS', '1', '00185050', undefined)
exports.PatientPosition = new Element(1593600, 'PatientPosition', 'CS', '1', '00185100', undefined)
exports.ViewPosition = new Element(1593601, 'ViewPosition', 'CS', '1', '00185101', undefined)
exports.ProjectionEponymousNameCodeSequence = new Element(1593604, 'ProjectionEponymousNameCodeSequence', 'SQ', '1', '00185104', undefined)
exports.ImageTransformationMatrix = new Element(1593872, 'ImageTransformationMatrix', 'DS', '6', '00185210', true)
exports.ImageTranslationVector = new Element(1593874, 'ImageTranslationVector', 'DS', '3', '00185212', true)
exports.Sensitivity = new Element(1597440, 'Sensitivity', 'DS', '1', '00186000', undefined)
exports.SequenceOfUltrasoundRegions = new Element(1597457, 'SequenceOfUltrasoundRegions', 'SQ', '1', '00186011', undefined)
exports.RegionSpatialFormat = new Element(1597458, 'RegionSpatialFormat', 'US', '1', '00186012', undefined)
exports.RegionDataType = new Element(1597460, 'RegionDataType', 'US', '1', '00186014', undefined)
exports.RegionFlags = new Element(1597462, 'RegionFlags', 'UL', '1', '00186016', undefined)
exports.RegionLocationMinX0 = new Element(1597464, 'RegionLocationMinX0', 'UL', '1', '00186018', undefined)
exports.RegionLocationMinY0 = new Element(1597466, 'RegionLocationMinY0', 'UL', '1', '0018601A', undefined)
exports.RegionLocationMaxX1 = new Element(1597468, 'RegionLocationMaxX1', 'UL', '1', '0018601C', undefined)
exports.RegionLocationMaxY1 = new Element(1597470, 'RegionLocationMaxY1', 'UL', '1', '0018601E', undefined)
exports.ReferencePixelX0 = new Element(1597472, 'ReferencePixelX0', 'SL', '1', '00186020', undefined)
exports.ReferencePixelY0 = new Element(1597474, 'ReferencePixelY0', 'SL', '1', '00186022', undefined)
exports.PhysicalUnitsXDirection = new Element(1597476, 'PhysicalUnitsXDirection', 'US', '1', '00186024', undefined)
exports.PhysicalUnitsYDirection = new Element(1597478, 'PhysicalUnitsYDirection', 'US', '1', '00186026', undefined)
exports.ReferencePixelPhysicalValueX = new Element(1597480, 'ReferencePixelPhysicalValueX', 'FD', '1', '00186028', undefined)
exports.ReferencePixelPhysicalValueY = new Element(1597482, 'ReferencePixelPhysicalValueY', 'FD', '1', '0018602A', undefined)
exports.PhysicalDeltaX = new Element(1597484, 'PhysicalDeltaX', 'FD', '1', '0018602C', undefined)
exports.PhysicalDeltaY = new Element(1597486, 'PhysicalDeltaY', 'FD', '1', '0018602E', undefined)
exports.TransducerFrequency = new Element(1597488, 'TransducerFrequency', 'UL', '1', '00186030', undefined)
exports.TransducerType = new Element(1597489, 'TransducerType', 'CS', '1', '00186031', undefined)
exports.PulseRepetitionFrequency = new Element(1597490, 'PulseRepetitionFrequency', 'UL', '1', '00186032', undefined)
exports.DopplerCorrectionAngle = new Element(1597492, 'DopplerCorrectionAngle', 'FD', '1', '00186034', undefined)
exports.SteeringAngle = new Element(1597494, 'SteeringAngle', 'FD', '1', '00186036', undefined)
exports.DopplerSampleVolumeXPositionRetired = new Element(1597496, 'DopplerSampleVolumeXPositionRetired', 'UL', '1', '00186038', true)
exports.DopplerSampleVolumeXPosition = new Element(1597497, 'DopplerSampleVolumeXPosition', 'SL', '1', '00186039', undefined)
exports.DopplerSampleVolumeYPositionRetired = new Element(1597498, 'DopplerSampleVolumeYPositionRetired', 'UL', '1', '0018603A', true)
exports.DopplerSampleVolumeYPosition = new Element(1597499, 'DopplerSampleVolumeYPosition', 'SL', '1', '0018603B', undefined)
exports.TMLinePositionX0Retired = new Element(1597500, 'TMLinePositionX0Retired', 'UL', '1', '0018603C', true)
exports.TMLinePositionX0 = new Element(1597501, 'TMLinePositionX0', 'SL', '1', '0018603D', undefined)
exports.TMLinePositionY0Retired = new Element(1597502, 'TMLinePositionY0Retired', 'UL', '1', '0018603E', true)
exports.TMLinePositionY0 = new Element(1597503, 'TMLinePositionY0', 'SL', '1', '0018603F', undefined)
exports.TMLinePositionX1Retired = new Element(1597504, 'TMLinePositionX1Retired', 'UL', '1', '00186040', true)
exports.TMLinePositionX1 = new Element(1597505, 'TMLinePositionX1', 'SL', '1', '00186041', undefined)
exports.TMLinePositionY1Retired = new Element(1597506, 'TMLinePositionY1Retired', 'UL', '1', '00186042', true)
exports.TMLinePositionY1 = new Element(1597507, 'TMLinePositionY1', 'SL', '1', '00186043', undefined)
exports.PixelComponentOrganization = new Element(1597508, 'PixelComponentOrganization', 'US', '1', '00186044', undefined)
exports.PixelComponentMask = new Element(1597510, 'PixelComponentMask', 'UL', '1', '00186046', undefined)
exports.PixelComponentRangeStart = new Element(1597512, 'PixelComponentRangeStart', 'UL', '1', '00186048', undefined)
exports.PixelComponentRangeStop = new Element(1597514, 'PixelComponentRangeStop', 'UL', '1', '0018604A', undefined)
exports.PixelComponentPhysicalUnits = new Element(1597516, 'PixelComponentPhysicalUnits', 'US', '1', '0018604C', undefined)
exports.PixelComponentDataType = new Element(1597518, 'PixelComponentDataType', 'US', '1', '0018604E', undefined)
exports.NumberOfTableBreakPoints = new Element(1597520, 'NumberOfTableBreakPoints', 'UL', '1', '00186050', undefined)
exports.TableOfXBreakPoints = new Element(1597522, 'TableOfXBreakPoints', 'UL', '1-n', '00186052', undefined)
exports.TableOfYBreakPoints = new Element(1597524, 'TableOfYBreakPoints', 'FD', '1-n', '00186054', undefined)
exports.NumberOfTableEntries = new Element(1597526, 'NumberOfTableEntries', 'UL', '1', '00186056', undefined)
exports.TableOfPixelValues = new Element(1597528, 'TableOfPixelValues', 'UL', '1-n', '00186058', undefined)
exports.TableOfParameterValues = new Element(1597530, 'TableOfParameterValues', 'FL', '1-n', '0018605A', undefined)
exports.RWaveTimeVector = new Element(1597536, 'RWaveTimeVector', 'FL', '1-n', '00186060', undefined)
exports.DetectorConditionsNominalFlag = new Element(1601536, 'DetectorConditionsNominalFlag', 'CS', '1', '00187000', undefined)
exports.DetectorTemperature = new Element(1601537, 'DetectorTemperature', 'DS', '1', '00187001', undefined)
exports.DetectorType = new Element(1601540, 'DetectorType', 'CS', '1', '00187004', undefined)
exports.DetectorConfiguration = new Element(1601541, 'DetectorConfiguration', 'CS', '1', '00187005', undefined)
exports.DetectorDescription = new Element(1601542, 'DetectorDescription', 'LT', '1', '00187006', undefined)
exports.DetectorMode = new Element(1601544, 'DetectorMode', 'LT', '1', '00187008', undefined)
exports.DetectorID = new Element(1601546, 'DetectorID', 'SH', '1', '0018700A', undefined)
exports.DateOfLastDetectorCalibration = new Element(1601548, 'DateOfLastDetectorCalibration', 'DA', '1', '0018700C', undefined)
exports.TimeOfLastDetectorCalibration = new Element(1601550, 'TimeOfLastDetectorCalibration', 'TM', '1', '0018700E', undefined)
exports.ExposuresOnDetectorSinceLastCalibration = new Element(1601552, 'ExposuresOnDetectorSinceLastCalibration', 'IS', '1', '00187010', undefined)
exports.ExposuresOnDetectorSinceManufactured = new Element(1601553, 'ExposuresOnDetectorSinceManufactured', 'IS', '1', '00187011', undefined)
exports.DetectorTimeSinceLastExposure = new Element(1601554, 'DetectorTimeSinceLastExposure', 'DS', '1', '00187012', undefined)
exports.DetectorActiveTime = new Element(1601556, 'DetectorActiveTime', 'DS', '1', '00187014', undefined)
exports.DetectorActivationOffsetFromExposure = new Element(1601558, 'DetectorActivationOffsetFromExposure', 'DS', '1', '00187016', undefined)
exports.DetectorBinning = new Element(1601562, 'DetectorBinning', 'DS', '2', '0018701A', undefined)
exports.DetectorElementPhysicalSize = new Element(1601568, 'DetectorElementPhysicalSize', 'DS', '2', '00187020', undefined)
exports.DetectorElementSpacing = new Element(1601570, 'DetectorElementSpacing', 'DS', '2', '00187022', undefined)
exports.DetectorActiveShape = new Element(1601572, 'DetectorActiveShape', 'CS', '1', '00187024', undefined)
exports.DetectorActiveDimensions = new Element(1601574, 'DetectorActiveDimensions', 'DS', '1-2', '00187026', undefined)
exports.DetectorActiveOrigin = new Element(1601576, 'DetectorActiveOrigin', 'DS', '2', '00187028', undefined)
exports.DetectorManufacturerName = new Element(1601578, 'DetectorManufacturerName', 'LO', '1', '0018702A', undefined)
exports.DetectorManufacturerModelName = new Element(1601579, 'DetectorManufacturerModelName', 'LO', '1', '0018702B', undefined)
exports.FieldOfViewOrigin = new Element(1601584, 'FieldOfViewOrigin', 'DS', '2', '00187030', undefined)
exports.FieldOfViewRotation = new Element(1601586, 'FieldOfViewRotation', 'DS', '1', '00187032', undefined)
exports.FieldOfViewHorizontalFlip = new Element(1601588, 'FieldOfViewHorizontalFlip', 'CS', '1', '00187034', undefined)
exports.PixelDataAreaOriginRelativeToFOV = new Element(1601590, 'PixelDataAreaOriginRelativeToFOV', 'FL', '2', '00187036', undefined)
exports.PixelDataAreaRotationAngleRelativeToFOV = new Element(1601592, 'PixelDataAreaRotationAngleRelativeToFOV', 'FL', '1', '00187038', undefined)
exports.GridAbsorbingMaterial = new Element(1601600, 'GridAbsorbingMaterial', 'LT', '1', '00187040', undefined)
exports.GridSpacingMaterial = new Element(1601601, 'GridSpacingMaterial', 'LT', '1', '00187041', undefined)
exports.GridThickness = new Element(1601602, 'GridThickness', 'DS', '1', '00187042', undefined)
exports.GridPitch = new Element(1601604, 'GridPitch', 'DS', '1', '00187044', undefined)
exports.GridAspectRatio = new Element(1601606, 'GridAspectRatio', 'IS', '2', '00187046', undefined)
exports.GridPeriod = new Element(1601608, 'GridPeriod', 'DS', '1', '00187048', undefined)
exports.GridFocalDistance = new Element(1601612, 'GridFocalDistance', 'DS', '1', '0018704C', undefined)
exports.FilterMaterial = new Element(1601616, 'FilterMaterial', 'CS', '1-n', '00187050', undefined)
exports.FilterThicknessMinimum = new Element(1601618, 'FilterThicknessMinimum', 'DS', '1-n', '00187052', undefined)
exports.FilterThicknessMaximum = new Element(1601620, 'FilterThicknessMaximum', 'DS', '1-n', '00187054', undefined)
exports.FilterBeamPathLengthMinimum = new Element(1601622, 'FilterBeamPathLengthMinimum', 'FL', '1-n', '00187056', undefined)
exports.FilterBeamPathLengthMaximum = new Element(1601624, 'FilterBeamPathLengthMaximum', 'FL', '1-n', '00187058', undefined)
exports.ExposureControlMode = new Element(1601632, 'ExposureControlMode', 'CS', '1', '00187060', undefined)
exports.ExposureControlModeDescription = new Element(1601634, 'ExposureControlModeDescription', 'LT', '1', '00187062', undefined)
exports.ExposureStatus = new Element(1601636, 'ExposureStatus', 'CS', '1', '00187064', undefined)
exports.PhototimerSetting = new Element(1601637, 'PhototimerSetting', 'DS', '1', '00187065', undefined)
exports.ExposureTimeInuS = new Element(1605968, 'ExposureTimeInuS', 'DS', '1', '00188150', undefined)
exports.XRayTubeCurrentInuA = new Element(1605969, 'XRayTubeCurrentInuA', 'DS', '1', '00188151', undefined)
exports.ContentQualification = new Element(1609732, 'ContentQualification', 'CS', '1', '00189004', undefined)
exports.PulseSequenceName = new Element(1609733, 'PulseSequenceName', 'SH', '1', '00189005', undefined)
exports.MRImagingModifierSequence = new Element(1609734, 'MRImagingModifierSequence', 'SQ', '1', '00189006', undefined)
exports.EchoPulseSequence = new Element(1609736, 'EchoPulseSequence', 'CS', '1', '00189008', undefined)
exports.InversionRecovery = new Element(1609737, 'InversionRecovery', 'CS', '1', '00189009', undefined)
exports.FlowCompensation = new Element(1609744, 'FlowCompensation', 'CS', '1', '00189010', undefined)
exports.MultipleSpinEcho = new Element(1609745, 'MultipleSpinEcho', 'CS', '1', '00189011', undefined)
exports.MultiPlanarExcitation = new Element(1609746, 'MultiPlanarExcitation', 'CS', '1', '00189012', undefined)
exports.PhaseContrast = new Element(1609748, 'PhaseContrast', 'CS', '1', '00189014', undefined)
exports.TimeOfFlightContrast = new Element(1609749, 'TimeOfFlightContrast', 'CS', '1', '00189015', undefined)
exports.Spoiling = new Element(1609750, 'Spoiling', 'CS', '1', '00189016', undefined)
exports.SteadyStatePulseSequence = new Element(1609751, 'SteadyStatePulseSequence', 'CS', '1', '00189017', undefined)
exports.EchoPlanarPulseSequence = new Element(1609752, 'EchoPlanarPulseSequence', 'CS', '1', '00189018', undefined)
exports.TagAngleFirstAxis = new Element(1609753, 'TagAngleFirstAxis', 'FD', '1', '00189019', undefined)
exports.MagnetizationTransfer = new Element(1609760, 'MagnetizationTransfer', 'CS', '1', '00189020', undefined)
exports.T2Preparation = new Element(1609761, 'T2Preparation', 'CS', '1', '00189021', undefined)
exports.BloodSignalNulling = new Element(1609762, 'BloodSignalNulling', 'CS', '1', '00189022', undefined)
exports.SaturationRecovery = new Element(1609764, 'SaturationRecovery', 'CS', '1', '00189024', undefined)
exports.SpectrallySelectedSuppression = new Element(1609765, 'SpectrallySelectedSuppression', 'CS', '1', '00189025', undefined)
exports.SpectrallySelectedExcitation = new Element(1609766, 'SpectrallySelectedExcitation', 'CS', '1', '00189026', undefined)
exports.SpatialPresaturation = new Element(1609767, 'SpatialPresaturation', 'CS', '1', '00189027', undefined)
exports.Tagging = new Element(1609768, 'Tagging', 'CS', '1', '00189028', undefined)
exports.OversamplingPhase = new Element(1609769, 'OversamplingPhase', 'CS', '1', '00189029', undefined)
exports.TagSpacingFirstDimension = new Element(1609776, 'TagSpacingFirstDimension', 'FD', '1', '00189030', undefined)
exports.GeometryOfKSpaceTraversal = new Element(1609778, 'GeometryOfKSpaceTraversal', 'CS', '1', '00189032', undefined)
exports.SegmentedKSpaceTraversal = new Element(1609779, 'SegmentedKSpaceTraversal', 'CS', '1', '00189033', undefined)
exports.RectilinearPhaseEncodeReordering = new Element(1609780, 'RectilinearPhaseEncodeReordering', 'CS', '1', '00189034', undefined)
exports.TagThickness = new Element(1609781, 'TagThickness', 'FD', '1', '00189035', undefined)
exports.PartialFourierDirection = new Element(1609782, 'PartialFourierDirection', 'CS', '1', '00189036', undefined)
exports.CardiacSynchronizationTechnique = new Element(1609783, 'CardiacSynchronizationTechnique', 'CS', '1', '00189037', undefined)
exports.ReceiveCoilManufacturerName = new Element(1609793, 'ReceiveCoilManufacturerName', 'LO', '1', '00189041', undefined)
exports.MRReceiveCoilSequence = new Element(1609794, 'MRReceiveCoilSequence', 'SQ', '1', '00189042', undefined)
exports.ReceiveCoilType = new Element(1609795, 'ReceiveCoilType', 'CS', '1', '00189043', undefined)
exports.QuadratureReceiveCoil = new Element(1609796, 'QuadratureReceiveCoil', 'CS', '1', '00189044', undefined)
exports.MultiCoilDefinitionSequence = new Element(1609797, 'MultiCoilDefinitionSequence', 'SQ', '1', '00189045', undefined)
exports.MultiCoilConfiguration = new Element(1609798, 'MultiCoilConfiguration', 'LO', '1', '00189046', undefined)
exports.MultiCoilElementName = new Element(1609799, 'MultiCoilElementName', 'SH', '1', '00189047', undefined)
exports.MultiCoilElementUsed = new Element(1609800, 'MultiCoilElementUsed', 'CS', '1', '00189048', undefined)
exports.MRTransmitCoilSequence = new Element(1609801, 'MRTransmitCoilSequence', 'SQ', '1', '00189049', undefined)
exports.TransmitCoilManufacturerName = new Element(1609808, 'TransmitCoilManufacturerName', 'LO', '1', '00189050', undefined)
exports.TransmitCoilType = new Element(1609809, 'TransmitCoilType', 'CS', '1', '00189051', undefined)
exports.SpectralWidth = new Element(1609810, 'SpectralWidth', 'FD', '1-2', '00189052', undefined)
exports.ChemicalShiftReference = new Element(1609811, 'ChemicalShiftReference', 'FD', '1-2', '00189053', undefined)
exports.VolumeLocalizationTechnique = new Element(1609812, 'VolumeLocalizationTechnique', 'CS', '1', '00189054', undefined)
exports.MRAcquisitionFrequencyEncodingSteps = new Element(1609816, 'MRAcquisitionFrequencyEncodingSteps', 'US', '1', '00189058', undefined)
exports.Decoupling = new Element(1609817, 'Decoupling', 'CS', '1', '00189059', undefined)
exports.DecoupledNucleus = new Element(1609824, 'DecoupledNucleus', 'CS', '1-2', '00189060', undefined)
exports.DecouplingFrequency = new Element(1609825, 'DecouplingFrequency', 'FD', '1-2', '00189061', undefined)
exports.DecouplingMethod = new Element(1609826, 'DecouplingMethod', 'CS', '1', '00189062', undefined)
exports.DecouplingChemicalShiftReference = new Element(1609827, 'DecouplingChemicalShiftReference', 'FD', '1-2', '00189063', undefined)
exports.KSpaceFiltering = new Element(1609828, 'KSpaceFiltering', 'CS', '1', '00189064', undefined)
exports.TimeDomainFiltering = new Element(1609829, 'TimeDomainFiltering', 'CS', '1-2', '00189065', undefined)
exports.NumberOfZeroFills = new Element(1609830, 'NumberOfZeroFills', 'US', '1-2', '00189066', undefined)
exports.BaselineCorrection = new Element(1609831, 'BaselineCorrection', 'CS', '1', '00189067', undefined)
exports.ParallelReductionFactorInPlane = new Element(1609833, 'ParallelReductionFactorInPlane', 'FD', '1', '00189069', undefined)
exports.CardiacRRIntervalSpecified = new Element(1609840, 'CardiacRRIntervalSpecified', 'FD', '1', '00189070', undefined)
exports.AcquisitionDuration = new Element(1609843, 'AcquisitionDuration', 'FD', '1', '00189073', undefined)
exports.FrameAcquisitionDateTime = new Element(1609844, 'FrameAcquisitionDateTime', 'DT', '1', '00189074', undefined)
exports.DiffusionDirectionality = new Element(1609845, 'DiffusionDirectionality', 'CS', '1', '00189075', undefined)
exports.DiffusionGradientDirectionSequence = new Element(1609846, 'DiffusionGradientDirectionSequence', 'SQ', '1', '00189076', undefined)
exports.ParallelAcquisition = new Element(1609847, 'ParallelAcquisition', 'CS', '1', '00189077', undefined)
exports.ParallelAcquisitionTechnique = new Element(1609848, 'ParallelAcquisitionTechnique', 'CS', '1', '00189078', undefined)
exports.InversionTimes = new Element(1609849, 'InversionTimes', 'FD', '1-n', '00189079', undefined)
exports.MetaboliteMapDescription = new Element(1609856, 'MetaboliteMapDescription', 'ST', '1', '00189080', undefined)
exports.PartialFourier = new Element(1609857, 'PartialFourier', 'CS', '1', '00189081', undefined)
exports.EffectiveEchoTime = new Element(1609858, 'EffectiveEchoTime', 'FD', '1', '00189082', undefined)
exports.MetaboliteMapCodeSequence = new Element(1609859, 'MetaboliteMapCodeSequence', 'SQ', '1', '00189083', undefined)
exports.ChemicalShiftSequence = new Element(1609860, 'ChemicalShiftSequence', 'SQ', '1', '00189084', undefined)
exports.CardiacSignalSource = new Element(1609861, 'CardiacSignalSource', 'CS', '1', '00189085', undefined)
exports.DiffusionBValue = new Element(1609863, 'DiffusionBValue', 'FD', '1', '00189087', undefined)
exports.DiffusionGradientOrientation = new Element(1609865, 'DiffusionGradientOrientation', 'FD', '3', '00189089', undefined)
exports.VelocityEncodingDirection = new Element(1609872, 'VelocityEncodingDirection', 'FD', '3', '00189090', undefined)
exports.VelocityEncodingMinimumValue = new Element(1609873, 'VelocityEncodingMinimumValue', 'FD', '1', '00189091', undefined)
exports.VelocityEncodingAcquisitionSequence = new Element(1609874, 'VelocityEncodingAcquisitionSequence', 'SQ', '1', '00189092', undefined)
exports.NumberOfKSpaceTrajectories = new Element(1609875, 'NumberOfKSpaceTrajectories', 'US', '1', '00189093', undefined)
exports.CoverageOfKSpace = new Element(1609876, 'CoverageOfKSpace', 'CS', '1', '00189094', undefined)
exports.SpectroscopyAcquisitionPhaseRows = new Element(1609877, 'SpectroscopyAcquisitionPhaseRows', 'UL', '1', '00189095', undefined)
exports.ParallelReductionFactorInPlaneRetired = new Element(1609878, 'ParallelReductionFactorInPlaneRetired', 'FD', '1', '00189096', true)
exports.TransmitterFrequency = new Element(1609880, 'TransmitterFrequency', 'FD', '1-2', '00189098', undefined)
exports.ResonantNucleus = new Element(1609984, 'ResonantNucleus', 'CS', '1-2', '00189100', undefined)
exports.FrequencyCorrection = new Element(1609985, 'FrequencyCorrection', 'CS', '1', '00189101', undefined)
exports.MRSpectroscopyFOVGeometrySequence = new Element(1609987, 'MRSpectroscopyFOVGeometrySequence', 'SQ', '1', '00189103', undefined)
exports.SlabThickness = new Element(1609988, 'SlabThickness', 'FD', '1', '00189104', undefined)
exports.SlabOrientation = new Element(1609989, 'SlabOrientation', 'FD', '3', '00189105', undefined)
exports.MidSlabPosition = new Element(1609990, 'MidSlabPosition', 'FD', '3', '00189106', undefined)
exports.MRSpatialSaturationSequence = new Element(1609991, 'MRSpatialSaturationSequence', 'SQ', '1', '00189107', undefined)
exports.MRTimingAndRelatedParametersSequence = new Element(1610002, 'MRTimingAndRelatedParametersSequence', 'SQ', '1', '00189112', undefined)
exports.MREchoSequence = new Element(1610004, 'MREchoSequence', 'SQ', '1', '00189114', undefined)
exports.MRModifierSequence = new Element(1610005, 'MRModifierSequence', 'SQ', '1', '00189115', undefined)
exports.MRDiffusionSequence = new Element(1610007, 'MRDiffusionSequence', 'SQ', '1', '00189117', undefined)
exports.CardiacSynchronizationSequence = new Element(1610008, 'CardiacSynchronizationSequence', 'SQ', '1', '00189118', undefined)
exports.MRAveragesSequence = new Element(1610009, 'MRAveragesSequence', 'SQ', '1', '00189119', undefined)
exports.MRFOVGeometrySequence = new Element(1610021, 'MRFOVGeometrySequence', 'SQ', '1', '00189125', undefined)
exports.VolumeLocalizationSequence = new Element(1610022, 'VolumeLocalizationSequence', 'SQ', '1', '00189126', undefined)
exports.SpectroscopyAcquisitionDataColumns = new Element(1610023, 'SpectroscopyAcquisitionDataColumns', 'UL', '1', '00189127', undefined)
exports.DiffusionAnisotropyType = new Element(1610055, 'DiffusionAnisotropyType', 'CS', '1', '00189147', undefined)
exports.FrameReferenceDateTime = new Element(1610065, 'FrameReferenceDateTime', 'DT', '1', '00189151', undefined)
exports.MRMetaboliteMapSequence = new Element(1610066, 'MRMetaboliteMapSequence', 'SQ', '1', '00189152', undefined)
exports.ParallelReductionFactorOutOfPlane = new Element(1610069, 'ParallelReductionFactorOutOfPlane', 'FD', '1', '00189155', undefined)
exports.SpectroscopyAcquisitionOutOfPlanePhaseSteps = new Element(1610073, 'SpectroscopyAcquisitionOutOfPlanePhaseSteps', 'UL', '1', '00189159', undefined)
exports.BulkMotionStatus = new Element(1610086, 'BulkMotionStatus', 'CS', '1', '00189166', true)
exports.ParallelReductionFactorSecondInPlane = new Element(1610088, 'ParallelReductionFactorSecondInPlane', 'FD', '1', '00189168', undefined)
exports.CardiacBeatRejectionTechnique = new Element(1610089, 'CardiacBeatRejectionTechnique', 'CS', '1', '00189169', undefined)
exports.RespiratoryMotionCompensationTechnique = new Element(1610096, 'RespiratoryMotionCompensationTechnique', 'CS', '1', '00189170', undefined)
exports.RespiratorySignalSource = new Element(1610097, 'RespiratorySignalSource', 'CS', '1', '00189171', undefined)
exports.BulkMotionCompensationTechnique = new Element(1610098, 'BulkMotionCompensationTechnique', 'CS', '1', '00189172', undefined)
exports.BulkMotionSignalSource = new Element(1610099, 'BulkMotionSignalSource', 'CS', '1', '00189173', undefined)
exports.ApplicableSafetyStandardAgency = new Element(1610100, 'ApplicableSafetyStandardAgency', 'CS', '1', '00189174', undefined)
exports.ApplicableSafetyStandardDescription = new Element(1610101, 'ApplicableSafetyStandardDescription', 'LO', '1', '00189175', undefined)
exports.OperatingModeSequence = new Element(1610102, 'OperatingModeSequence', 'SQ', '1', '00189176', undefined)
exports.OperatingModeType = new Element(1610103, 'OperatingModeType', 'CS', '1', '00189177', undefined)
exports.OperatingMode = new Element(1610104, 'OperatingMode', 'CS', '1', '00189178', undefined)
exports.SpecificAbsorptionRateDefinition = new Element(1610105, 'SpecificAbsorptionRateDefinition', 'CS', '1', '00189179', undefined)
exports.GradientOutputType = new Element(1610112, 'GradientOutputType', 'CS', '1', '00189180', undefined)
exports.SpecificAbsorptionRateValue = new Element(1610113, 'SpecificAbsorptionRateValue', 'FD', '1', '00189181', undefined)
exports.GradientOutput = new Element(1610114, 'GradientOutput', 'FD', '1', '00189182', undefined)
exports.FlowCompensationDirection = new Element(1610115, 'FlowCompensationDirection', 'CS', '1', '00189183', undefined)
exports.TaggingDelay = new Element(1610116, 'TaggingDelay', 'FD', '1', '00189184', undefined)
exports.RespiratoryMotionCompensationTechniqueDescription = new Element(1610117, 'RespiratoryMotionCompensationTechniqueDescription', 'ST', '1', '00189185', undefined)
exports.RespiratorySignalSourceID = new Element(1610118, 'RespiratorySignalSourceID', 'SH', '1', '00189186', undefined)
exports.ChemicalShiftMinimumIntegrationLimitInHz = new Element(1610133, 'ChemicalShiftMinimumIntegrationLimitInHz', 'FD', '1', '00189195', true)
exports.ChemicalShiftMaximumIntegrationLimitInHz = new Element(1610134, 'ChemicalShiftMaximumIntegrationLimitInHz', 'FD', '1', '00189196', true)
exports.MRVelocityEncodingSequence = new Element(1610135, 'MRVelocityEncodingSequence', 'SQ', '1', '00189197', undefined)
exports.FirstOrderPhaseCorrection = new Element(1610136, 'FirstOrderPhaseCorrection', 'CS', '1', '00189198', undefined)
exports.WaterReferencedPhaseCorrection = new Element(1610137, 'WaterReferencedPhaseCorrection', 'CS', '1', '00189199', undefined)
exports.MRSpectroscopyAcquisitionType = new Element(1610240, 'MRSpectroscopyAcquisitionType', 'CS', '1', '00189200', undefined)
exports.RespiratoryCyclePosition = new Element(1610260, 'RespiratoryCyclePosition', 'CS', '1', '00189214', undefined)
exports.VelocityEncodingMaximumValue = new Element(1610263, 'VelocityEncodingMaximumValue', 'FD', '1', '00189217', undefined)
exports.TagSpacingSecondDimension = new Element(1610264, 'TagSpacingSecondDimension', 'FD', '1', '00189218', undefined)
exports.TagAngleSecondAxis = new Element(1610265, 'TagAngleSecondAxis', 'SS', '1', '00189219', undefined)
exports.FrameAcquisitionDuration = new Element(1610272, 'FrameAcquisitionDuration', 'FD', '1', '00189220', undefined)
exports.MRImageFrameTypeSequence = new Element(1610278, 'MRImageFrameTypeSequence', 'SQ', '1', '00189226', undefined)
exports.MRSpectroscopyFrameTypeSequence = new Element(1610279, 'MRSpectroscopyFrameTypeSequence', 'SQ', '1', '00189227', undefined)
exports.MRAcquisitionPhaseEncodingStepsInPlane = new Element(1610289, 'MRAcquisitionPhaseEncodingStepsInPlane', 'US', '1', '00189231', undefined)
exports.MRAcquisitionPhaseEncodingStepsOutOfPlane = new Element(1610290, 'MRAcquisitionPhaseEncodingStepsOutOfPlane', 'US', '1', '00189232', undefined)
exports.SpectroscopyAcquisitionPhaseColumns = new Element(1610292, 'SpectroscopyAcquisitionPhaseColumns', 'UL', '1', '00189234', undefined)
exports.CardiacCyclePosition = new Element(1610294, 'CardiacCyclePosition', 'CS', '1', '00189236', undefined)
exports.SpecificAbsorptionRateSequence = new Element(1610297, 'SpecificAbsorptionRateSequence', 'SQ', '1', '00189239', undefined)
exports.RFEchoTrainLength = new Element(1610304, 'RFEchoTrainLength', 'US', '1', '00189240', undefined)
exports.GradientEchoTrainLength = new Element(1610305, 'GradientEchoTrainLength', 'US', '1', '00189241', undefined)
exports.ArterialSpinLabelingContrast = new Element(1610320, 'ArterialSpinLabelingContrast', 'CS', '1', '00189250', undefined)
exports.MRArterialSpinLabelingSequence = new Element(1610321, 'MRArterialSpinLabelingSequence', 'SQ', '1', '00189251', undefined)
exports.ASLTechniqueDescription = new Element(1610322, 'ASLTechniqueDescription', 'LO', '1', '00189252', undefined)
exports.ASLSlabNumber = new Element(1610323, 'ASLSlabNumber', 'US', '1', '00189253', undefined)
exports.ASLSlabThickness = new Element(1610324, 'ASLSlabThickness', 'FD', '1', '00189254', undefined)
exports.ASLSlabOrientation = new Element(1610325, 'ASLSlabOrientation', 'FD', '3', '00189255', undefined)
exports.ASLMidSlabPosition = new Element(1610326, 'ASLMidSlabPosition', 'FD', '3', '00189256', undefined)
exports.ASLContext = new Element(1610327, 'ASLContext', 'CS', '1', '00189257', undefined)
exports.ASLPulseTrainDuration = new Element(1610328, 'ASLPulseTrainDuration', 'UL', '1', '00189258', undefined)
exports.ASLCrusherFlag = new Element(1610329, 'ASLCrusherFlag', 'CS', '1', '00189259', undefined)
exports.ASLCrusherFlowLimit = new Element(1610330, 'ASLCrusherFlowLimit', 'FD', '1', '0018925A', undefined)
exports.ASLCrusherDescription = new Element(1610331, 'ASLCrusherDescription', 'LO', '1', '0018925B', undefined)
exports.ASLBolusCutoffFlag = new Element(1610332, 'ASLBolusCutoffFlag', 'CS', '1', '0018925C', undefined)
exports.ASLBolusCutoffTimingSequence = new Element(1610333, 'ASLBolusCutoffTimingSequence', 'SQ', '1', '0018925D', undefined)
exports.ASLBolusCutoffTechnique = new Element(1610334, 'ASLBolusCutoffTechnique', 'LO', '1', '0018925E', undefined)
exports.ASLBolusCutoffDelayTime = new Element(1610335, 'ASLBolusCutoffDelayTime', 'UL', '1', '0018925F', undefined)
exports.ASLSlabSequence = new Element(1610336, 'ASLSlabSequence', 'SQ', '1', '00189260', undefined)
exports.ChemicalShiftMinimumIntegrationLimitInppm = new Element(1610389, 'ChemicalShiftMinimumIntegrationLimitInppm', 'FD', '1', '00189295', undefined)
exports.ChemicalShiftMaximumIntegrationLimitInppm = new Element(1610390, 'ChemicalShiftMaximumIntegrationLimitInppm', 'FD', '1', '00189296', undefined)
exports.WaterReferenceAcquisition = new Element(1610391, 'WaterReferenceAcquisition', 'CS', '1', '00189297', undefined)
exports.EchoPeakPosition = new Element(1610392, 'EchoPeakPosition', 'IS', '1', '00189298', undefined)
exports.CTAcquisitionTypeSequence = new Element(1610497, 'CTAcquisitionTypeSequence', 'SQ', '1', '00189301', undefined)
exports.AcquisitionType = new Element(1610498, 'AcquisitionType', 'CS', '1', '00189302', undefined)
exports.TubeAngle = new Element(1610499, 'TubeAngle', 'FD', '1', '00189303', undefined)
exports.CTAcquisitionDetailsSequence = new Element(1610500, 'CTAcquisitionDetailsSequence', 'SQ', '1', '00189304', undefined)
exports.RevolutionTime = new Element(1610501, 'RevolutionTime', 'FD', '1', '00189305', undefined)
exports.SingleCollimationWidth = new Element(1610502, 'SingleCollimationWidth', 'FD', '1', '00189306', undefined)
exports.TotalCollimationWidth = new Element(1610503, 'TotalCollimationWidth', 'FD', '1', '00189307', undefined)
exports.CTTableDynamicsSequence = new Element(1610504, 'CTTableDynamicsSequence', 'SQ', '1', '00189308', undefined)
exports.TableSpeed = new Element(1610505, 'TableSpeed', 'FD', '1', '00189309', undefined)
exports.TableFeedPerRotation = new Element(1610512, 'TableFeedPerRotation', 'FD', '1', '00189310', undefined)
exports.SpiralPitchFactor = new Element(1610513, 'SpiralPitchFactor', 'FD', '1', '00189311', undefined)
exports.CTGeometrySequence = new Element(1610514, 'CTGeometrySequence', 'SQ', '1', '00189312', undefined)
exports.DataCollectionCenterPatient = new Element(1610515, 'DataCollectionCenterPatient', 'FD', '3', '00189313', undefined)
exports.CTReconstructionSequence = new Element(1610516, 'CTReconstructionSequence', 'SQ', '1', '00189314', undefined)
exports.ReconstructionAlgorithm = new Element(1610517, 'ReconstructionAlgorithm', 'CS', '1', '00189315', undefined)
exports.ConvolutionKernelGroup = new Element(1610518, 'ConvolutionKernelGroup', 'CS', '1', '00189316', undefined)
exports.ReconstructionFieldOfView = new Element(1610519, 'ReconstructionFieldOfView', 'FD', '2', '00189317', undefined)
exports.ReconstructionTargetCenterPatient = new Element(1610520, 'ReconstructionTargetCenterPatient', 'FD', '3', '00189318', undefined)
exports.ReconstructionAngle = new Element(1610521, 'ReconstructionAngle', 'FD', '1', '00189319', undefined)
exports.ImageFilter = new Element(1610528, 'ImageFilter', 'SH', '1', '00189320', undefined)
exports.CTExposureSequence = new Element(1610529, 'CTExposureSequence', 'SQ', '1', '00189321', undefined)
exports.ReconstructionPixelSpacing = new Element(1610530, 'ReconstructionPixelSpacing', 'FD', '2', '00189322', undefined)
exports.ExposureModulationType = new Element(1610531, 'ExposureModulationType', 'CS', '1', '00189323', undefined)
exports.EstimatedDoseSaving = new Element(1610532, 'EstimatedDoseSaving', 'FD', '1', '00189324', undefined)
exports.CTXRayDetailsSequence = new Element(1610533, 'CTXRayDetailsSequence', 'SQ', '1', '00189325', undefined)
exports.CTPositionSequence = new Element(1610534, 'CTPositionSequence', 'SQ', '1', '00189326', undefined)
exports.TablePosition = new Element(1610535, 'TablePosition', 'FD', '1', '00189327', undefined)
exports.ExposureTimeInms = new Element(1610536, 'ExposureTimeInms', 'FD', '1', '00189328', undefined)
exports.CTImageFrameTypeSequence = new Element(1610537, 'CTImageFrameTypeSequence', 'SQ', '1', '00189329', undefined)
exports.XRayTubeCurrentInmA = new Element(1610544, 'XRayTubeCurrentInmA', 'FD', '1', '00189330', undefined)
exports.ExposureInmAs = new Element(1610546, 'ExposureInmAs', 'FD', '1', '00189332', undefined)
exports.ConstantVolumeFlag = new Element(1610547, 'ConstantVolumeFlag', 'CS', '1', '00189333', undefined)
exports.FluoroscopyFlag = new Element(1610548, 'FluoroscopyFlag', 'CS', '1', '00189334', undefined)
exports.DistanceSourceToDataCollectionCenter = new Element(1610549, 'DistanceSourceToDataCollectionCenter', 'FD', '1', '00189335', undefined)
exports.ContrastBolusAgentNumber = new Element(1610551, 'ContrastBolusAgentNumber', 'US', '1', '00189337', undefined)
exports.ContrastBolusIngredientCodeSequence = new Element(1610552, 'ContrastBolusIngredientCodeSequence', 'SQ', '1', '00189338', undefined)
exports.ContrastAdministrationProfileSequence = new Element(1610560, 'ContrastAdministrationProfileSequence', 'SQ', '1', '00189340', undefined)
exports.ContrastBolusUsageSequence = new Element(1610561, 'ContrastBolusUsageSequence', 'SQ', '1', '00189341', undefined)
exports.ContrastBolusAgentAdministered = new Element(1610562, 'ContrastBolusAgentAdministered', 'CS', '1', '00189342', undefined)
exports.ContrastBolusAgentDetected = new Element(1610563, 'ContrastBolusAgentDetected', 'CS', '1', '00189343', undefined)
exports.ContrastBolusAgentPhase = new Element(1610564, 'ContrastBolusAgentPhase', 'CS', '1', '00189344', undefined)
exports.CTDIvol = new Element(1610565, 'CTDIvol', 'FD', '1', '00189345', undefined)
exports.CTDIPhantomTypeCodeSequence = new Element(1610566, 'CTDIPhantomTypeCodeSequence', 'SQ', '1', '00189346', undefined)
exports.CalciumScoringMassFactorPatient = new Element(1610577, 'CalciumScoringMassFactorPatient', 'FL', '1', '00189351', undefined)
exports.CalciumScoringMassFactorDevice = new Element(1610578, 'CalciumScoringMassFactorDevice', 'FL', '3', '00189352', undefined)
exports.EnergyWeightingFactor = new Element(1610579, 'EnergyWeightingFactor', 'FL', '1', '00189353', undefined)
exports.CTAdditionalXRaySourceSequence = new Element(1610592, 'CTAdditionalXRaySourceSequence', 'SQ', '1', '00189360', undefined)
exports.ProjectionPixelCalibrationSequence = new Element(1610753, 'ProjectionPixelCalibrationSequence', 'SQ', '1', '00189401', undefined)
exports.DistanceSourceToIsocenter = new Element(1610754, 'DistanceSourceToIsocenter', 'FL', '1', '00189402', undefined)
exports.DistanceObjectToTableTop = new Element(1610755, 'DistanceObjectToTableTop', 'FL', '1', '00189403', undefined)
exports.ObjectPixelSpacingInCenterOfBeam = new Element(1610756, 'ObjectPixelSpacingInCenterOfBeam', 'FL', '2', '00189404', undefined)
exports.PositionerPositionSequence = new Element(1610757, 'PositionerPositionSequence', 'SQ', '1', '00189405', undefined)
exports.TablePositionSequence = new Element(1610758, 'TablePositionSequence', 'SQ', '1', '00189406', undefined)
exports.CollimatorShapeSequence = new Element(1610759, 'CollimatorShapeSequence', 'SQ', '1', '00189407', undefined)
exports.PlanesInAcquisition = new Element(1610768, 'PlanesInAcquisition', 'CS', '1', '00189410', undefined)
exports.XAXRFFrameCharacteristicsSequence = new Element(1610770, 'XAXRFFrameCharacteristicsSequence', 'SQ', '1', '00189412', undefined)
exports.FrameAcquisitionSequence = new Element(1610775, 'FrameAcquisitionSequence', 'SQ', '1', '00189417', undefined)
exports.XRayReceptorType = new Element(1610784, 'XRayReceptorType', 'CS', '1', '00189420', undefined)
exports.AcquisitionProtocolName = new Element(1610787, 'AcquisitionProtocolName', 'LO', '1', '00189423', undefined)
exports.AcquisitionProtocolDescription = new Element(1610788, 'AcquisitionProtocolDescription', 'LT', '1', '00189424', undefined)
exports.ContrastBolusIngredientOpaque = new Element(1610789, 'ContrastBolusIngredientOpaque', 'CS', '1', '00189425', undefined)
exports.DistanceReceptorPlaneToDetectorHousing = new Element(1610790, 'DistanceReceptorPlaneToDetectorHousing', 'FL', '1', '00189426', undefined)
exports.IntensifierActiveShape = new Element(1610791, 'IntensifierActiveShape', 'CS', '1', '00189427', undefined)
exports.IntensifierActiveDimensions = new Element(1610792, 'IntensifierActiveDimensions', 'FL', '1-2', '00189428', undefined)
exports.PhysicalDetectorSize = new Element(1610793, 'PhysicalDetectorSize', 'FL', '2', '00189429', undefined)
exports.PositionOfIsocenterProjection = new Element(1610800, 'PositionOfIsocenterProjection', 'FL', '2', '00189430', undefined)
exports.FieldOfViewSequence = new Element(1610802, 'FieldOfViewSequence', 'SQ', '1', '00189432', undefined)
exports.FieldOfViewDescription = new Element(1610803, 'FieldOfViewDescription', 'LO', '1', '00189433', undefined)
exports.ExposureControlSensingRegionsSequence = new Element(1610804, 'ExposureControlSensingRegionsSequence', 'SQ', '1', '00189434', undefined)
exports.ExposureControlSensingRegionShape = new Element(1610805, 'ExposureControlSensingRegionShape', 'CS', '1', '00189435', undefined)
exports.ExposureControlSensingRegionLeftVerticalEdge = new Element(1610806, 'ExposureControlSensingRegionLeftVerticalEdge', 'SS', '1', '00189436', undefined)
exports.ExposureControlSensingRegionRightVerticalEdge = new Element(1610807, 'ExposureControlSensingRegionRightVerticalEdge', 'SS', '1', '00189437', undefined)
exports.ExposureControlSensingRegionUpperHorizontalEdge = new Element(1610808, 'ExposureControlSensingRegionUpperHorizontalEdge', 'SS', '1', '00189438', undefined)
exports.ExposureControlSensingRegionLowerHorizontalEdge = new Element(1610809, 'ExposureControlSensingRegionLowerHorizontalEdge', 'SS', '1', '00189439', undefined)
exports.CenterOfCircularExposureControlSensingRegion = new Element(1610816, 'CenterOfCircularExposureControlSensingRegion', 'SS', '2', '00189440', undefined)
exports.RadiusOfCircularExposureControlSensingRegion = new Element(1610817, 'RadiusOfCircularExposureControlSensingRegion', 'US', '1', '00189441', undefined)
exports.VerticesOfThePolygonalExposureControlSensingRegion = new Element(1610818, 'VerticesOfThePolygonalExposureControlSensingRegion', 'SS', '2-n', '00189442', undefined)
exports.ColumnAngulationPatient = new Element(1610823, 'ColumnAngulationPatient', 'FL', '1', '00189447', undefined)
exports.BeamAngle = new Element(1610825, 'BeamAngle', 'FL', '1', '00189449', undefined)
exports.FrameDetectorParametersSequence = new Element(1610833, 'FrameDetectorParametersSequence', 'SQ', '1', '00189451', undefined)
exports.CalculatedAnatomyThickness = new Element(1610834, 'CalculatedAnatomyThickness', 'FL', '1', '00189452', undefined)
exports.CalibrationSequence = new Element(1610837, 'CalibrationSequence', 'SQ', '1', '00189455', undefined)
exports.ObjectThicknessSequence = new Element(1610838, 'ObjectThicknessSequence', 'SQ', '1', '00189456', undefined)
exports.PlaneIdentification = new Element(1610839, 'PlaneIdentification', 'CS', '1', '00189457', undefined)
exports.FieldOfViewDimensionsInFloat = new Element(1610849, 'FieldOfViewDimensionsInFloat', 'FL', '1-2', '00189461', undefined)
exports.IsocenterReferenceSystemSequence = new Element(1610850, 'IsocenterReferenceSystemSequence', 'SQ', '1', '00189462', undefined)
exports.PositionerIsocenterPrimaryAngle = new Element(1610851, 'PositionerIsocenterPrimaryAngle', 'FL', '1', '00189463', undefined)
exports.PositionerIsocenterSecondaryAngle = new Element(1610852, 'PositionerIsocenterSecondaryAngle', 'FL', '1', '00189464', undefined)
exports.PositionerIsocenterDetectorRotationAngle = new Element(1610853, 'PositionerIsocenterDetectorRotationAngle', 'FL', '1', '00189465', undefined)
exports.TableXPositionToIsocenter = new Element(1610854, 'TableXPositionToIsocenter', 'FL', '1', '00189466', undefined)
exports.TableYPositionToIsocenter = new Element(1610855, 'TableYPositionToIsocenter', 'FL', '1', '00189467', undefined)
exports.TableZPositionToIsocenter = new Element(1610856, 'TableZPositionToIsocenter', 'FL', '1', '00189468', undefined)
exports.TableHorizontalRotationAngle = new Element(1610857, 'TableHorizontalRotationAngle', 'FL', '1', '00189469', undefined)
exports.TableHeadTiltAngle = new Element(1610864, 'TableHeadTiltAngle', 'FL', '1', '00189470', undefined)
exports.TableCradleTiltAngle = new Element(1610865, 'TableCradleTiltAngle', 'FL', '1', '00189471', undefined)
exports.FrameDisplayShutterSequence = new Element(1610866, 'FrameDisplayShutterSequence', 'SQ', '1', '00189472', undefined)
exports.AcquiredImageAreaDoseProduct = new Element(1610867, 'AcquiredImageAreaDoseProduct', 'FL', '1', '00189473', undefined)
exports.CArmPositionerTabletopRelationship = new Element(1610868, 'CArmPositionerTabletopRelationship', 'CS', '1', '00189474', undefined)
exports.XRayGeometrySequence = new Element(1610870, 'XRayGeometrySequence', 'SQ', '1', '00189476', undefined)
exports.IrradiationEventIdentificationSequence = new Element(1610871, 'IrradiationEventIdentificationSequence', 'SQ', '1', '00189477', undefined)
exports.XRay3DFrameTypeSequence = new Element(1611012, 'XRay3DFrameTypeSequence', 'SQ', '1', '00189504', undefined)
exports.ContributingSourcesSequence = new Element(1611014, 'ContributingSourcesSequence', 'SQ', '1', '00189506', undefined)
exports.XRay3DAcquisitionSequence = new Element(1611015, 'XRay3DAcquisitionSequence', 'SQ', '1', '00189507', undefined)
exports.PrimaryPositionerScanArc = new Element(1611016, 'PrimaryPositionerScanArc', 'FL', '1', '00189508', undefined)
exports.SecondaryPositionerScanArc = new Element(1611017, 'SecondaryPositionerScanArc', 'FL', '1', '00189509', undefined)
exports.PrimaryPositionerScanStartAngle = new Element(1611024, 'PrimaryPositionerScanStartAngle', 'FL', '1', '00189510', undefined)
exports.SecondaryPositionerScanStartAngle = new Element(1611025, 'SecondaryPositionerScanStartAngle', 'FL', '1', '00189511', undefined)
exports.PrimaryPositionerIncrement = new Element(1611028, 'PrimaryPositionerIncrement', 'FL', '1', '00189514', undefined)
exports.SecondaryPositionerIncrement = new Element(1611029, 'SecondaryPositionerIncrement', 'FL', '1', '00189515', undefined)
exports.StartAcquisitionDateTime = new Element(1611030, 'StartAcquisitionDateTime', 'DT', '1', '00189516', undefined)
exports.EndAcquisitionDateTime = new Element(1611031, 'EndAcquisitionDateTime', 'DT', '1', '00189517', undefined)
exports.PrimaryPositionerIncrementSign = new Element(1611032, 'PrimaryPositionerIncrementSign', 'SS', '1', '00189518', undefined)
exports.SecondaryPositionerIncrementSign = new Element(1611033, 'SecondaryPositionerIncrementSign', 'SS', '1', '00189519', undefined)
exports.ApplicationName = new Element(1611044, 'ApplicationName', 'LO', '1', '00189524', undefined)
exports.ApplicationVersion = new Element(1611045, 'ApplicationVersion', 'LO', '1', '00189525', undefined)
exports.ApplicationManufacturer = new Element(1611046, 'ApplicationManufacturer', 'LO', '1', '00189526', undefined)
exports.AlgorithmType = new Element(1611047, 'AlgorithmType', 'CS', '1', '00189527', undefined)
exports.AlgorithmDescription = new Element(1611048, 'AlgorithmDescription', 'LO', '1', '00189528', undefined)
exports.XRay3DReconstructionSequence = new Element(1611056, 'XRay3DReconstructionSequence', 'SQ', '1', '00189530', undefined)
exports.ReconstructionDescription = new Element(1611057, 'ReconstructionDescription', 'LO', '1', '00189531', undefined)
exports.PerProjectionAcquisitionSequence = new Element(1611064, 'PerProjectionAcquisitionSequence', 'SQ', '1', '00189538', undefined)
exports.DetectorPositionSequence = new Element(1611073, 'DetectorPositionSequence', 'SQ', '1', '00189541', undefined)
exports.XRayAcquisitionDoseSequence = new Element(1611074, 'XRayAcquisitionDoseSequence', 'SQ', '1', '00189542', undefined)
exports.XRaySourceIsocenterPrimaryAngle = new Element(1611075, 'XRaySourceIsocenterPrimaryAngle', 'FD', '1', '00189543', undefined)
exports.XRaySourceIsocenterSecondaryAngle = new Element(1611076, 'XRaySourceIsocenterSecondaryAngle', 'FD', '1', '00189544', undefined)
exports.BreastSupportIsocenterPrimaryAngle = new Element(1611077, 'BreastSupportIsocenterPrimaryAngle', 'FD', '1', '00189545', undefined)
exports.BreastSupportIsocenterSecondaryAngle = new Element(1611078, 'BreastSupportIsocenterSecondaryAngle', 'FD', '1', '00189546', undefined)
exports.BreastSupportXPositionToIsocenter = new Element(1611079, 'BreastSupportXPositionToIsocenter', 'FD', '1', '00189547', undefined)
exports.BreastSupportYPositionToIsocenter = new Element(1611080, 'BreastSupportYPositionToIsocenter', 'FD', '1', '00189548', undefined)
exports.BreastSupportZPositionToIsocenter = new Element(1611081, 'BreastSupportZPositionToIsocenter', 'FD', '1', '00189549', undefined)
exports.DetectorIsocenterPrimaryAngle = new Element(1611088, 'DetectorIsocenterPrimaryAngle', 'FD', '1', '00189550', undefined)
exports.DetectorIsocenterSecondaryAngle = new Element(1611089, 'DetectorIsocenterSecondaryAngle', 'FD', '1', '00189551', undefined)
exports.DetectorXPositionToIsocenter = new Element(1611090, 'DetectorXPositionToIsocenter', 'FD', '1', '00189552', undefined)
exports.DetectorYPositionToIsocenter = new Element(1611091, 'DetectorYPositionToIsocenter', 'FD', '1', '00189553', undefined)
exports.DetectorZPositionToIsocenter = new Element(1611092, 'DetectorZPositionToIsocenter', 'FD', '1', '00189554', undefined)
exports.XRayGridSequence = new Element(1611093, 'XRayGridSequence', 'SQ', '1', '00189555', undefined)
exports.XRayFilterSequence = new Element(1611094, 'XRayFilterSequence', 'SQ', '1', '00189556', undefined)
exports.DetectorActiveAreaTLHCPosition = new Element(1611095, 'DetectorActiveAreaTLHCPosition', 'FD', '3', '00189557', undefined)
exports.DetectorActiveAreaOrientation = new Element(1611096, 'DetectorActiveAreaOrientation', 'FD', '6', '00189558', undefined)
exports.PositionerPrimaryAngleDirection = new Element(1611097, 'PositionerPrimaryAngleDirection', 'CS', '1', '00189559', undefined)
exports.DiffusionBMatrixSequence = new Element(1611265, 'DiffusionBMatrixSequence', 'SQ', '1', '00189601', undefined)
exports.DiffusionBValueXX = new Element(1611266, 'DiffusionBValueXX', 'FD', '1', '00189602', undefined)
exports.DiffusionBValueXY = new Element(1611267, 'DiffusionBValueXY', 'FD', '1', '00189603', undefined)
exports.DiffusionBValueXZ = new Element(1611268, 'DiffusionBValueXZ', 'FD', '1', '00189604', undefined)
exports.DiffusionBValueYY = new Element(1611269, 'DiffusionBValueYY', 'FD', '1', '00189605', undefined)
exports.DiffusionBValueYZ = new Element(1611270, 'DiffusionBValueYZ', 'FD', '1', '00189606', undefined)
exports.DiffusionBValueZZ = new Element(1611271, 'DiffusionBValueZZ', 'FD', '1', '00189607', undefined)
exports.DecayCorrectionDateTime = new Element(1611521, 'DecayCorrectionDateTime', 'DT', '1', '00189701', undefined)
exports.StartDensityThreshold = new Element(1611541, 'StartDensityThreshold', 'FD', '1', '00189715', undefined)
exports.StartRelativeDensityDifferenceThreshold = new Element(1611542, 'StartRelativeDensityDifferenceThreshold', 'FD', '1', '00189716', undefined)
exports.StartCardiacTriggerCountThreshold = new Element(1611543, 'StartCardiacTriggerCountThreshold', 'FD', '1', '00189717', undefined)
exports.StartRespiratoryTriggerCountThreshold = new Element(1611544, 'StartRespiratoryTriggerCountThreshold', 'FD', '1', '00189718', undefined)
exports.TerminationCountsThreshold = new Element(1611545, 'TerminationCountsThreshold', 'FD', '1', '00189719', undefined)
exports.TerminationDensityThreshold = new Element(1611552, 'TerminationDensityThreshold', 'FD', '1', '00189720', undefined)
exports.TerminationRelativeDensityThreshold = new Element(1611553, 'TerminationRelativeDensityThreshold', 'FD', '1', '00189721', undefined)
exports.TerminationTimeThreshold = new Element(1611554, 'TerminationTimeThreshold', 'FD', '1', '00189722', undefined)
exports.TerminationCardiacTriggerCountThreshold = new Element(1611555, 'TerminationCardiacTriggerCountThreshold', 'FD', '1', '00189723', undefined)
exports.TerminationRespiratoryTriggerCountThreshold = new Element(1611556, 'TerminationRespiratoryTriggerCountThreshold', 'FD', '1', '00189724', undefined)
exports.DetectorGeometry = new Element(1611557, 'DetectorGeometry', 'CS', '1', '00189725', undefined)
exports.TransverseDetectorSeparation = new Element(1611558, 'TransverseDetectorSeparation', 'FD', '1', '00189726', undefined)
exports.AxialDetectorDimension = new Element(1611559, 'AxialDetectorDimension', 'FD', '1', '00189727', undefined)
exports.RadiopharmaceuticalAgentNumber = new Element(1611561, 'RadiopharmaceuticalAgentNumber', 'US', '1', '00189729', undefined)
exports.PETFrameAcquisitionSequence = new Element(1611570, 'PETFrameAcquisitionSequence', 'SQ', '1', '00189732', undefined)
exports.PETDetectorMotionDetailsSequence = new Element(1611571, 'PETDetectorMotionDetailsSequence', 'SQ', '1', '00189733', undefined)
exports.PETTableDynamicsSequence = new Element(1611572, 'PETTableDynamicsSequence', 'SQ', '1', '00189734', undefined)
exports.PETPositionSequence = new Element(1611573, 'PETPositionSequence', 'SQ', '1', '00189735', undefined)
exports.PETFrameCorrectionFactorsSequence = new Element(1611574, 'PETFrameCorrectionFactorsSequence', 'SQ', '1', '00189736', undefined)
exports.RadiopharmaceuticalUsageSequence = new Element(1611575, 'RadiopharmaceuticalUsageSequence', 'SQ', '1', '00189737', undefined)
exports.AttenuationCorrectionSource = new Element(1611576, 'AttenuationCorrectionSource', 'CS', '1', '00189738', undefined)
exports.NumberOfIterations = new Element(1611577, 'NumberOfIterations', 'US', '1', '00189739', undefined)
exports.NumberOfSubsets = new Element(1611584, 'NumberOfSubsets', 'US', '1', '00189740', undefined)
exports.PETReconstructionSequence = new Element(1611593, 'PETReconstructionSequence', 'SQ', '1', '00189749', undefined)
exports.PETFrameTypeSequence = new Element(1611601, 'PETFrameTypeSequence', 'SQ', '1', '00189751', undefined)
exports.TimeOfFlightInformationUsed = new Element(1611605, 'TimeOfFlightInformationUsed', 'CS', '1', '00189755', undefined)
exports.ReconstructionType = new Element(1611606, 'ReconstructionType', 'CS', '1', '00189756', undefined)
exports.DecayCorrected = new Element(1611608, 'DecayCorrected', 'CS', '1', '00189758', undefined)
exports.AttenuationCorrected = new Element(1611609, 'AttenuationCorrected', 'CS', '1', '00189759', undefined)
exports.ScatterCorrected = new Element(1611616, 'ScatterCorrected', 'CS', '1', '00189760', undefined)
exports.DeadTimeCorrected = new Element(1611617, 'DeadTimeCorrected', 'CS', '1', '00189761', undefined)
exports.GantryMotionCorrected = new Element(1611618, 'GantryMotionCorrected', 'CS', '1', '00189762', undefined)
exports.PatientMotionCorrected = new Element(1611619, 'PatientMotionCorrected', 'CS', '1', '00189763', undefined)
exports.CountLossNormalizationCorrected = new Element(1611620, 'CountLossNormalizationCorrected', 'CS', '1', '00189764', undefined)
exports.RandomsCorrected = new Element(1611621, 'RandomsCorrected', 'CS', '1', '00189765', undefined)
exports.NonUniformRadialSamplingCorrected = new Element(1611622, 'NonUniformRadialSamplingCorrected', 'CS', '1', '00189766', undefined)
exports.SensitivityCalibrated = new Element(1611623, 'SensitivityCalibrated', 'CS', '1', '00189767', undefined)
exports.DetectorNormalizationCorrection = new Element(1611624, 'DetectorNormalizationCorrection', 'CS', '1', '00189768', undefined)
exports.IterativeReconstructionMethod = new Element(1611625, 'IterativeReconstructionMethod', 'CS', '1', '00189769', undefined)
exports.AttenuationCorrectionTemporalRelationship = new Element(1611632, 'AttenuationCorrectionTemporalRelationship', 'CS', '1', '00189770', undefined)
exports.PatientPhysiologicalStateSequence = new Element(1611633, 'PatientPhysiologicalStateSequence', 'SQ', '1', '00189771', undefined)
exports.PatientPhysiologicalStateCodeSequence = new Element(1611634, 'PatientPhysiologicalStateCodeSequence', 'SQ', '1', '00189772', undefined)
exports.DepthsOfFocus = new Element(1611777, 'DepthsOfFocus', 'FD', '1-n', '00189801', undefined)
exports.ExcludedIntervalsSequence = new Element(1611779, 'ExcludedIntervalsSequence', 'SQ', '1', '00189803', undefined)
exports.ExclusionStartDateTime = new Element(1611780, 'ExclusionStartDateTime', 'DT', '1', '00189804', undefined)
exports.ExclusionDuration = new Element(1611781, 'ExclusionDuration', 'FD', '1', '00189805', undefined)
exports.USImageDescriptionSequence = new Element(1611782, 'USImageDescriptionSequence', 'SQ', '1', '00189806', undefined)
exports.ImageDataTypeSequence = new Element(1611783, 'ImageDataTypeSequence', 'SQ', '1', '00189807', undefined)
exports.DataType = new Element(1611784, 'DataType', 'CS', '1', '00189808', undefined)
exports.TransducerScanPatternCodeSequence = new Element(1611785, 'TransducerScanPatternCodeSequence', 'SQ', '1', '00189809', undefined)
exports.AliasedDataType = new Element(1611787, 'AliasedDataType', 'CS', '1', '0018980B', undefined)
exports.PositionMeasuringDeviceUsed = new Element(1611788, 'PositionMeasuringDeviceUsed', 'CS', '1', '0018980C', undefined)
exports.TransducerGeometryCodeSequence = new Element(1611789, 'TransducerGeometryCodeSequence', 'SQ', '1', '0018980D', undefined)
exports.TransducerBeamSteeringCodeSequence = new Element(1611790, 'TransducerBeamSteeringCodeSequence', 'SQ', '1', '0018980E', undefined)
exports.TransducerApplicationCodeSequence = new Element(1611791, 'TransducerApplicationCodeSequence', 'SQ', '1', '0018980F', undefined)
exports.ZeroVelocityPixelValue = new Element(1611792, 'ZeroVelocityPixelValue', 'US or SS', '1', '00189810', undefined)
exports.ContributingEquipmentSequence = new Element(1613825, 'ContributingEquipmentSequence', 'SQ', '1', '0018A001', undefined)
exports.ContributionDateTime = new Element(1613826, 'ContributionDateTime', 'DT', '1', '0018A002', undefined)
exports.ContributionDescription = new Element(1613827, 'ContributionDescription', 'ST', '1', '0018A003', undefined)
exports.StudyInstanceUID = new Element(2097165, 'StudyInstanceUID', 'UI', '1', '0020000D', undefined)
exports.SeriesInstanceUID = new Element(2097166, 'SeriesInstanceUID', 'UI', '1', '0020000E', undefined)
exports.StudyID = new Element(2097168, 'StudyID', 'SH', '1', '00200010', undefined)
exports.SeriesNumber = new Element(2097169, 'SeriesNumber', 'IS', '1', '00200011', undefined)
exports.AcquisitionNumber = new Element(2097170, 'AcquisitionNumber', 'IS', '1', '00200012', undefined)
exports.InstanceNumber = new Element(2097171, 'InstanceNumber', 'IS', '1', '00200013', undefined)
exports.IsotopeNumber = new Element(2097172, 'IsotopeNumber', 'IS', '1', '00200014', true)
exports.PhaseNumber = new Element(2097173, 'PhaseNumber', 'IS', '1', '00200015', true)
exports.IntervalNumber = new Element(2097174, 'IntervalNumber', 'IS', '1', '00200016', true)
exports.TimeSlotNumber = new Element(2097175, 'TimeSlotNumber', 'IS', '1', '00200017', true)
exports.AngleNumber = new Element(2097176, 'AngleNumber', 'IS', '1', '00200018', true)
exports.ItemNumber = new Element(2097177, 'ItemNumber', 'IS', '1', '00200019', undefined)
exports.PatientOrientation = new Element(2097184, 'PatientOrientation', 'CS', '2', '00200020', undefined)
exports.OverlayNumber = new Element(2097186, 'OverlayNumber', 'IS', '1', '00200022', true)
exports.CurveNumber = new Element(2097188, 'CurveNumber', 'IS', '1', '00200024', true)
exports.LUTNumber = new Element(2097190, 'LUTNumber', 'IS', '1', '00200026', true)
exports.ImagePosition = new Element(2097200, 'ImagePosition', 'DS', '3', '00200030', true)
exports.ImagePositionPatient = new Element(2097202, 'ImagePositionPatient', 'DS', '3', '00200032', undefined)
exports.ImageOrientation = new Element(2097205, 'ImageOrientation', 'DS', '6', '00200035', true)
exports.ImageOrientationPatient = new Element(2097207, 'ImageOrientationPatient', 'DS', '6', '00200037', undefined)
exports.Location = new Element(2097232, 'Location', 'DS', '1', '00200050', true)
exports.FrameOfReferenceUID = new Element(2097234, 'FrameOfReferenceUID', 'UI', '1', '00200052', undefined)
exports.Laterality = new Element(2097248, 'Laterality', 'CS', '1', '00200060', undefined)
exports.ImageLaterality = new Element(2097250, 'ImageLaterality', 'CS', '1', '00200062', undefined)
exports.ImageGeometryType = new Element(2097264, 'ImageGeometryType', 'LO', '1', '00200070', true)
exports.MaskingImage = new Element(2097280, 'MaskingImage', 'CS', '1-n', '00200080', true)
exports.ReportNumber = new Element(2097322, 'ReportNumber', 'IS', '1', '002000AA', true)
exports.TemporalPositionIdentifier = new Element(2097408, 'TemporalPositionIdentifier', 'IS', '1', '00200100', undefined)
exports.NumberOfTemporalPositions = new Element(2097413, 'NumberOfTemporalPositions', 'IS', '1', '00200105', undefined)
exports.TemporalResolution = new Element(2097424, 'TemporalResolution', 'DS', '1', '00200110', undefined)
exports.SynchronizationFrameOfReferenceUID = new Element(2097664, 'SynchronizationFrameOfReferenceUID', 'UI', '1', '00200200', undefined)
exports.SOPInstanceUIDOfConcatenationSource = new Element(2097730, 'SOPInstanceUIDOfConcatenationSource', 'UI', '1', '00200242', undefined)
exports.SeriesInStudy = new Element(2101248, 'SeriesInStudy', 'IS', '1', '00201000', true)
exports.AcquisitionsInSeries = new Element(2101249, 'AcquisitionsInSeries', 'IS', '1', '00201001', true)
exports.ImagesInAcquisition = new Element(2101250, 'ImagesInAcquisition', 'IS', '1', '00201002', undefined)
exports.ImagesInSeries = new Element(2101251, 'ImagesInSeries', 'IS', '1', '00201003', true)
exports.AcquisitionsInStudy = new Element(2101252, 'AcquisitionsInStudy', 'IS', '1', '00201004', true)
exports.ImagesInStudy = new Element(2101253, 'ImagesInStudy', 'IS', '1', '00201005', true)
exports.Reference = new Element(2101280, 'Reference', 'LO', '1-n', '00201020', true)
exports.PositionReferenceIndicator = new Element(2101312, 'PositionReferenceIndicator', 'LO', '1', '00201040', undefined)
exports.SliceLocation = new Element(2101313, 'SliceLocation', 'DS', '1', '00201041', undefined)
exports.OtherStudyNumbers = new Element(2101360, 'OtherStudyNumbers', 'IS', '1-n', '00201070', true)
exports.NumberOfPatientRelatedStudies = new Element(2101760, 'NumberOfPatientRelatedStudies', 'IS', '1', '00201200', undefined)
exports.NumberOfPatientRelatedSeries = new Element(2101762, 'NumberOfPatientRelatedSeries', 'IS', '1', '00201202', undefined)
exports.NumberOfPatientRelatedInstances = new Element(2101764, 'NumberOfPatientRelatedInstances', 'IS', '1', '00201204', undefined)
exports.NumberOfStudyRelatedSeries = new Element(2101766, 'NumberOfStudyRelatedSeries', 'IS', '1', '00201206', undefined)
exports.NumberOfStudyRelatedInstances = new Element(2101768, 'NumberOfStudyRelatedInstances', 'IS', '1', '00201208', undefined)
exports.NumberOfSeriesRelatedInstances = new Element(2101769, 'NumberOfSeriesRelatedInstances', 'IS', '1', '00201209', undefined)
exports.SourceImageIDs = new Element(2109696, 'SourceImageIDs', 'CS', '1-n', '002031xx', true)
exports.ModifyingDeviceID = new Element(2110465, 'ModifyingDeviceID', 'CS', '1', '00203401', true)
exports.ModifiedImageID = new Element(2110466, 'ModifiedImageID', 'CS', '1', '00203402', true)
exports.ModifiedImageDate = new Element(2110467, 'ModifiedImageDate', 'DA', '1', '00203403', true)
exports.ModifyingDeviceManufacturer = new Element(2110468, 'ModifyingDeviceManufacturer', 'LO', '1', '00203404', true)
exports.ModifiedImageTime = new Element(2110469, 'ModifiedImageTime', 'TM', '1', '00203405', true)
exports.ModifiedImageDescription = new Element(2110470, 'ModifiedImageDescription', 'LO', '1', '00203406', true)
exports.ImageComments = new Element(2113536, 'ImageComments', 'LT', '1', '00204000', undefined)
exports.OriginalImageIdentification = new Element(2117632, 'OriginalImageIdentification', 'AT', '1-n', '00205000', true)
exports.OriginalImageIdentificationNomenclature = new Element(2117634, 'OriginalImageIdentificationNomenclature', 'LO', '1-n', '00205002', true)
exports.StackID = new Element(2134102, 'StackID', 'SH', '1', '00209056', undefined)
exports.InStackPositionNumber = new Element(2134103, 'InStackPositionNumber', 'UL', '1', '00209057', undefined)
exports.FrameAnatomySequence = new Element(2134129, 'FrameAnatomySequence', 'SQ', '1', '00209071', undefined)
exports.FrameLaterality = new Element(2134130, 'FrameLaterality', 'CS', '1', '00209072', undefined)
exports.FrameContentSequence = new Element(2134289, 'FrameContentSequence', 'SQ', '1', '00209111', undefined)
exports.PlanePositionSequence = new Element(2134291, 'PlanePositionSequence', 'SQ', '1', '00209113', undefined)
exports.PlaneOrientationSequence = new Element(2134294, 'PlaneOrientationSequence', 'SQ', '1', '00209116', undefined)
exports.TemporalPositionIndex = new Element(2134312, 'TemporalPositionIndex', 'UL', '1', '00209128', undefined)
exports.NominalCardiacTriggerDelayTime = new Element(2134355, 'NominalCardiacTriggerDelayTime', 'FD', '1', '00209153', undefined)
exports.NominalCardiacTriggerTimePriorToRPeak = new Element(2134356, 'NominalCardiacTriggerTimePriorToRPeak', 'FL', '1', '00209154', undefined)
exports.ActualCardiacTriggerTimePriorToRPeak = new Element(2134357, 'ActualCardiacTriggerTimePriorToRPeak', 'FL', '1', '00209155', undefined)
exports.FrameAcquisitionNumber = new Element(2134358, 'FrameAcquisitionNumber', 'US', '1', '00209156', undefined)
exports.DimensionIndexValues = new Element(2134359, 'DimensionIndexValues', 'UL', '1-n', '00209157', undefined)
exports.FrameComments = new Element(2134360, 'FrameComments', 'LT', '1', '00209158', undefined)
exports.ConcatenationUID = new Element(2134369, 'ConcatenationUID', 'UI', '1', '00209161', undefined)
exports.InConcatenationNumber = new Element(2134370, 'InConcatenationNumber', 'US', '1', '00209162', undefined)
exports.InConcatenationTotalNumber = new Element(2134371, 'InConcatenationTotalNumber', 'US', '1', '00209163', undefined)
exports.DimensionOrganizationUID = new Element(2134372, 'DimensionOrganizationUID', 'UI', '1', '00209164', undefined)
exports.DimensionIndexPointer = new Element(2134373, 'DimensionIndexPointer', 'AT', '1', '00209165', undefined)
exports.FunctionalGroupPointer = new Element(2134375, 'FunctionalGroupPointer', 'AT', '1', '00209167', undefined)
exports.UnassignedSharedConvertedAttributesSequence = new Element(2134384, 'UnassignedSharedConvertedAttributesSequence', 'SQ', '1', '00209170', undefined)
exports.UnassignedPerFrameConvertedAttributesSequence = new Element(2134385, 'UnassignedPerFrameConvertedAttributesSequence', 'SQ', '1', '00209171', undefined)
exports.ConversionSourceAttributesSequence = new Element(2134386, 'ConversionSourceAttributesSequence', 'SQ', '1', '00209172', undefined)
exports.DimensionIndexPrivateCreator = new Element(2134547, 'DimensionIndexPrivateCreator', 'LO', '1', '00209213', undefined)
exports.DimensionOrganizationSequence = new Element(2134561, 'DimensionOrganizationSequence', 'SQ', '1', '00209221', undefined)
exports.DimensionIndexSequence = new Element(2134562, 'DimensionIndexSequence', 'SQ', '1', '00209222', undefined)
exports.ConcatenationFrameOffsetNumber = new Element(2134568, 'ConcatenationFrameOffsetNumber', 'UL', '1', '00209228', undefined)
exports.FunctionalGroupPrivateCreator = new Element(2134584, 'FunctionalGroupPrivateCreator', 'LO', '1', '00209238', undefined)
exports.NominalPercentageOfCardiacPhase = new Element(2134593, 'NominalPercentageOfCardiacPhase', 'FL', '1', '00209241', undefined)
exports.NominalPercentageOfRespiratoryPhase = new Element(2134597, 'NominalPercentageOfRespiratoryPhase', 'FL', '1', '00209245', undefined)
exports.StartingRespiratoryAmplitude = new Element(2134598, 'StartingRespiratoryAmplitude', 'FL', '1', '00209246', undefined)
exports.StartingRespiratoryPhase = new Element(2134599, 'StartingRespiratoryPhase', 'CS', '1', '00209247', undefined)
exports.EndingRespiratoryAmplitude = new Element(2134600, 'EndingRespiratoryAmplitude', 'FL', '1', '00209248', undefined)
exports.EndingRespiratoryPhase = new Element(2134601, 'EndingRespiratoryPhase', 'CS', '1', '00209249', undefined)
exports.RespiratoryTriggerType = new Element(2134608, 'RespiratoryTriggerType', 'CS', '1', '00209250', undefined)
exports.RRIntervalTimeNominal = new Element(2134609, 'RRIntervalTimeNominal', 'FD', '1', '00209251', undefined)
exports.ActualCardiacTriggerDelayTime = new Element(2134610, 'ActualCardiacTriggerDelayTime', 'FD', '1', '00209252', undefined)
exports.RespiratorySynchronizationSequence = new Element(2134611, 'RespiratorySynchronizationSequence', 'SQ', '1', '00209253', undefined)
exports.RespiratoryIntervalTime = new Element(2134612, 'RespiratoryIntervalTime', 'FD', '1', '00209254', undefined)
exports.NominalRespiratoryTriggerDelayTime = new Element(2134613, 'NominalRespiratoryTriggerDelayTime', 'FD', '1', '00209255', undefined)
exports.RespiratoryTriggerDelayThreshold = new Element(2134614, 'RespiratoryTriggerDelayThreshold', 'FD', '1', '00209256', undefined)
exports.ActualRespiratoryTriggerDelayTime = new Element(2134615, 'ActualRespiratoryTriggerDelayTime', 'FD', '1', '00209257', undefined)
exports.ImagePositionVolume = new Element(2134785, 'ImagePositionVolume', 'FD', '3', '00209301', undefined)
exports.ImageOrientationVolume = new Element(2134786, 'ImageOrientationVolume', 'FD', '6', '00209302', undefined)
exports.UltrasoundAcquisitionGeometry = new Element(2134791, 'UltrasoundAcquisitionGeometry', 'CS', '1', '00209307', undefined)
exports.ApexPosition = new Element(2134792, 'ApexPosition', 'FD', '3', '00209308', undefined)
exports.VolumeToTransducerMappingMatrix = new Element(2134793, 'VolumeToTransducerMappingMatrix', 'FD', '16', '00209309', undefined)
exports.VolumeToTableMappingMatrix = new Element(2134794, 'VolumeToTableMappingMatrix', 'FD', '16', '0020930A', undefined)
exports.VolumeToTransducerRelationship = new Element(2134795, 'VolumeToTransducerRelationship', 'CS', '1', '0020930B', undefined)
exports.PatientFrameOfReferenceSource = new Element(2134796, 'PatientFrameOfReferenceSource', 'CS', '1', '0020930C', undefined)
exports.TemporalPositionTimeOffset = new Element(2134797, 'TemporalPositionTimeOffset', 'FD', '1', '0020930D', undefined)
exports.PlanePositionVolumeSequence = new Element(2134798, 'PlanePositionVolumeSequence', 'SQ', '1', '0020930E', undefined)
exports.PlaneOrientationVolumeSequence = new Element(2134799, 'PlaneOrientationVolumeSequence', 'SQ', '1', '0020930F', undefined)
exports.TemporalPositionSequence = new Element(2134800, 'TemporalPositionSequence', 'SQ', '1', '00209310', undefined)
exports.DimensionOrganizationType = new Element(2134801, 'DimensionOrganizationType', 'CS', '1', '00209311', undefined)
exports.VolumeFrameOfReferenceUID = new Element(2134802, 'VolumeFrameOfReferenceUID', 'UI', '1', '00209312', undefined)
exports.TableFrameOfReferenceUID = new Element(2134803, 'TableFrameOfReferenceUID', 'UI', '1', '00209313', undefined)
exports.DimensionDescriptionLabel = new Element(2135073, 'DimensionDescriptionLabel', 'LO', '1', '00209421', undefined)
exports.PatientOrientationInFrameSequence = new Element(2135120, 'PatientOrientationInFrameSequence', 'SQ', '1', '00209450', undefined)
exports.FrameLabel = new Element(2135123, 'FrameLabel', 'LO', '1', '00209453', undefined)
exports.AcquisitionIndex = new Element(2135320, 'AcquisitionIndex', 'US', '1-n', '00209518', undefined)
exports.ContributingSOPInstancesReferenceSequence = new Element(2135337, 'ContributingSOPInstancesReferenceSequence', 'SQ', '1', '00209529', undefined)
exports.ReconstructionIndex = new Element(2135350, 'ReconstructionIndex', 'US', '1', '00209536', undefined)
exports.LightPathFilterPassThroughWavelength = new Element(2228225, 'LightPathFilterPassThroughWavelength', 'US', '1', '00220001', undefined)
exports.LightPathFilterPassBand = new Element(2228226, 'LightPathFilterPassBand', 'US', '2', '00220002', undefined)
exports.ImagePathFilterPassThroughWavelength = new Element(2228227, 'ImagePathFilterPassThroughWavelength', 'US', '1', '00220003', undefined)
exports.ImagePathFilterPassBand = new Element(2228228, 'ImagePathFilterPassBand', 'US', '2', '00220004', undefined)
exports.PatientEyeMovementCommanded = new Element(2228229, 'PatientEyeMovementCommanded', 'CS', '1', '00220005', undefined)
exports.PatientEyeMovementCommandCodeSequence = new Element(2228230, 'PatientEyeMovementCommandCodeSequence', 'SQ', '1', '00220006', undefined)
exports.SphericalLensPower = new Element(2228231, 'SphericalLensPower', 'FL', '1', '00220007', undefined)
exports.CylinderLensPower = new Element(2228232, 'CylinderLensPower', 'FL', '1', '00220008', undefined)
exports.CylinderAxis = new Element(2228233, 'CylinderAxis', 'FL', '1', '00220009', undefined)
exports.EmmetropicMagnification = new Element(2228234, 'EmmetropicMagnification', 'FL', '1', '0022000A', undefined)
exports.IntraOcularPressure = new Element(2228235, 'IntraOcularPressure', 'FL', '1', '0022000B', undefined)
exports.HorizontalFieldOfView = new Element(2228236, 'HorizontalFieldOfView', 'FL', '1', '0022000C', undefined)
exports.PupilDilated = new Element(2228237, 'PupilDilated', 'CS', '1', '0022000D', undefined)
exports.DegreeOfDilation = new Element(2228238, 'DegreeOfDilation', 'FL', '1', '0022000E', undefined)
exports.StereoBaselineAngle = new Element(2228240, 'StereoBaselineAngle', 'FL', '1', '00220010', undefined)
exports.StereoBaselineDisplacement = new Element(2228241, 'StereoBaselineDisplacement', 'FL', '1', '00220011', undefined)
exports.StereoHorizontalPixelOffset = new Element(2228242, 'StereoHorizontalPixelOffset', 'FL', '1', '00220012', undefined)
exports.StereoVerticalPixelOffset = new Element(2228243, 'StereoVerticalPixelOffset', 'FL', '1', '00220013', undefined)
exports.StereoRotation = new Element(2228244, 'StereoRotation', 'FL', '1', '00220014', undefined)
exports.AcquisitionDeviceTypeCodeSequence = new Element(2228245, 'AcquisitionDeviceTypeCodeSequence', 'SQ', '1', '00220015', undefined)
exports.IlluminationTypeCodeSequence = new Element(2228246, 'IlluminationTypeCodeSequence', 'SQ', '1', '00220016', undefined)
exports.LightPathFilterTypeStackCodeSequence = new Element(2228247, 'LightPathFilterTypeStackCodeSequence', 'SQ', '1', '00220017', undefined)
exports.ImagePathFilterTypeStackCodeSequence = new Element(2228248, 'ImagePathFilterTypeStackCodeSequence', 'SQ', '1', '00220018', undefined)
exports.LensesCodeSequence = new Element(2228249, 'LensesCodeSequence', 'SQ', '1', '00220019', undefined)
exports.ChannelDescriptionCodeSequence = new Element(2228250, 'ChannelDescriptionCodeSequence', 'SQ', '1', '0022001A', undefined)
exports.RefractiveStateSequence = new Element(2228251, 'RefractiveStateSequence', 'SQ', '1', '0022001B', undefined)
exports.MydriaticAgentCodeSequence = new Element(2228252, 'MydriaticAgentCodeSequence', 'SQ', '1', '0022001C', undefined)
exports.RelativeImagePositionCodeSequence = new Element(2228253, 'RelativeImagePositionCodeSequence', 'SQ', '1', '0022001D', undefined)
exports.CameraAngleOfView = new Element(2228254, 'CameraAngleOfView', 'FL', '1', '0022001E', undefined)
exports.StereoPairsSequence = new Element(2228256, 'StereoPairsSequence', 'SQ', '1', '00220020', undefined)
exports.LeftImageSequence = new Element(2228257, 'LeftImageSequence', 'SQ', '1', '00220021', undefined)
exports.RightImageSequence = new Element(2228258, 'RightImageSequence', 'SQ', '1', '00220022', undefined)
exports.AxialLengthOfTheEye = new Element(2228272, 'AxialLengthOfTheEye', 'FL', '1', '00220030', undefined)
exports.OphthalmicFrameLocationSequence = new Element(2228273, 'OphthalmicFrameLocationSequence', 'SQ', '1', '00220031', undefined)
exports.ReferenceCoordinates = new Element(2228274, 'ReferenceCoordinates', 'FL', '2-2n', '00220032', undefined)
exports.DepthSpatialResolution = new Element(2228277, 'DepthSpatialResolution', 'FL', '1', '00220035', undefined)
exports.MaximumDepthDistortion = new Element(2228278, 'MaximumDepthDistortion', 'FL', '1', '00220036', undefined)
exports.AlongScanSpatialResolution = new Element(2228279, 'AlongScanSpatialResolution', 'FL', '1', '00220037', undefined)
exports.MaximumAlongScanDistortion = new Element(2228280, 'MaximumAlongScanDistortion', 'FL', '1', '00220038', undefined)
exports.OphthalmicImageOrientation = new Element(2228281, 'OphthalmicImageOrientation', 'CS', '1', '00220039', undefined)
exports.DepthOfTransverseImage = new Element(2228289, 'DepthOfTransverseImage', 'FL', '1', '00220041', undefined)
exports.MydriaticAgentConcentrationUnitsSequence = new Element(2228290, 'MydriaticAgentConcentrationUnitsSequence', 'SQ', '1', '00220042', undefined)
exports.AcrossScanSpatialResolution = new Element(2228296, 'AcrossScanSpatialResolution', 'FL', '1', '00220048', undefined)
exports.MaximumAcrossScanDistortion = new Element(2228297, 'MaximumAcrossScanDistortion', 'FL', '1', '00220049', undefined)
exports.MydriaticAgentConcentration = new Element(2228302, 'MydriaticAgentConcentration', 'DS', '1', '0022004E', undefined)
exports.IlluminationWaveLength = new Element(2228309, 'IlluminationWaveLength', 'FL', '1', '00220055', undefined)
exports.IlluminationPower = new Element(2228310, 'IlluminationPower', 'FL', '1', '00220056', undefined)
exports.IlluminationBandwidth = new Element(2228311, 'IlluminationBandwidth', 'FL', '1', '00220057', undefined)
exports.MydriaticAgentSequence = new Element(2228312, 'MydriaticAgentSequence', 'SQ', '1', '00220058', undefined)
exports.OphthalmicAxialMeasurementsRightEyeSequence = new Element(2232327, 'OphthalmicAxialMeasurementsRightEyeSequence', 'SQ', '1', '00221007', undefined)
exports.OphthalmicAxialMeasurementsLeftEyeSequence = new Element(2232328, 'OphthalmicAxialMeasurementsLeftEyeSequence', 'SQ', '1', '00221008', undefined)
exports.OphthalmicAxialMeasurementsDeviceType = new Element(2232329, 'OphthalmicAxialMeasurementsDeviceType', 'CS', '1', '00221009', undefined)
exports.OphthalmicAxialLengthMeasurementsType = new Element(2232336, 'OphthalmicAxialLengthMeasurementsType', 'CS', '1', '00221010', undefined)
exports.OphthalmicAxialLengthSequence = new Element(2232338, 'OphthalmicAxialLengthSequence', 'SQ', '1', '00221012', undefined)
exports.OphthalmicAxialLength = new Element(2232345, 'OphthalmicAxialLength', 'FL', '1', '00221019', undefined)
exports.LensStatusCodeSequence = new Element(2232356, 'LensStatusCodeSequence', 'SQ', '1', '00221024', undefined)
exports.VitreousStatusCodeSequence = new Element(2232357, 'VitreousStatusCodeSequence', 'SQ', '1', '00221025', undefined)
exports.IOLFormulaCodeSequence = new Element(2232360, 'IOLFormulaCodeSequence', 'SQ', '1', '00221028', undefined)
exports.IOLFormulaDetail = new Element(2232361, 'IOLFormulaDetail', 'LO', '1', '00221029', undefined)
exports.KeratometerIndex = new Element(2232371, 'KeratometerIndex', 'FL', '1', '00221033', undefined)
exports.SourceOfOphthalmicAxialLengthCodeSequence = new Element(2232373, 'SourceOfOphthalmicAxialLengthCodeSequence', 'SQ', '1', '00221035', undefined)
exports.TargetRefraction = new Element(2232375, 'TargetRefraction', 'FL', '1', '00221037', undefined)
exports.RefractiveProcedureOccurred = new Element(2232377, 'RefractiveProcedureOccurred', 'CS', '1', '00221039', undefined)
exports.RefractiveSurgeryTypeCodeSequence = new Element(2232384, 'RefractiveSurgeryTypeCodeSequence', 'SQ', '1', '00221040', undefined)
exports.OphthalmicUltrasoundMethodCodeSequence = new Element(2232388, 'OphthalmicUltrasoundMethodCodeSequence', 'SQ', '1', '00221044', undefined)
exports.OphthalmicAxialLengthMeasurementsSequence = new Element(2232400, 'OphthalmicAxialLengthMeasurementsSequence', 'SQ', '1', '00221050', undefined)
exports.IOLPower = new Element(2232403, 'IOLPower', 'FL', '1', '00221053', undefined)
exports.PredictedRefractiveError = new Element(2232404, 'PredictedRefractiveError', 'FL', '1', '00221054', undefined)
exports.OphthalmicAxialLengthVelocity = new Element(2232409, 'OphthalmicAxialLengthVelocity', 'FL', '1', '00221059', undefined)
exports.LensStatusDescription = new Element(2232421, 'LensStatusDescription', 'LO', '1', '00221065', undefined)
exports.VitreousStatusDescription = new Element(2232422, 'VitreousStatusDescription', 'LO', '1', '00221066', undefined)
exports.IOLPowerSequence = new Element(2232464, 'IOLPowerSequence', 'SQ', '1', '00221090', undefined)
exports.LensConstantSequence = new Element(2232466, 'LensConstantSequence', 'SQ', '1', '00221092', undefined)
exports.IOLManufacturer = new Element(2232467, 'IOLManufacturer', 'LO', '1', '00221093', undefined)
exports.LensConstantDescription = new Element(2232468, 'LensConstantDescription', 'LO', '1', '00221094', true)
exports.ImplantName = new Element(2232469, 'ImplantName', 'LO', '1', '00221095', undefined)
exports.KeratometryMeasurementTypeCodeSequence = new Element(2232470, 'KeratometryMeasurementTypeCodeSequence', 'SQ', '1', '00221096', undefined)
exports.ImplantPartNumber = new Element(2232471, 'ImplantPartNumber', 'LO', '1', '00221097', undefined)
exports.ReferencedOphthalmicAxialMeasurementsSequence = new Element(2232576, 'ReferencedOphthalmicAxialMeasurementsSequence', 'SQ', '1', '00221100', undefined)
exports.OphthalmicAxialLengthMeasurementsSegmentNameCodeSequence = new Element(2232577, 'OphthalmicAxialLengthMeasurementsSegmentNameCodeSequence', 'SQ', '1', '00221101', undefined)
exports.RefractiveErrorBeforeRefractiveSurgeryCodeSequence = new Element(2232579, 'RefractiveErrorBeforeRefractiveSurgeryCodeSequence', 'SQ', '1', '00221103', undefined)
exports.IOLPowerForExactEmmetropia = new Element(2232609, 'IOLPowerForExactEmmetropia', 'FL', '1', '00221121', undefined)
exports.IOLPowerForExactTargetRefraction = new Element(2232610, 'IOLPowerForExactTargetRefraction', 'FL', '1', '00221122', undefined)
exports.AnteriorChamberDepthDefinitionCodeSequence = new Element(2232613, 'AnteriorChamberDepthDefinitionCodeSequence', 'SQ', '1', '00221125', undefined)
exports.LensThicknessSequence = new Element(2232615, 'LensThicknessSequence', 'SQ', '1', '00221127', undefined)
exports.AnteriorChamberDepthSequence = new Element(2232616, 'AnteriorChamberDepthSequence', 'SQ', '1', '00221128', undefined)
exports.LensThickness = new Element(2232624, 'LensThickness', 'FL', '1', '00221130', undefined)
exports.AnteriorChamberDepth = new Element(2232625, 'AnteriorChamberDepth', 'FL', '1', '00221131', undefined)
exports.SourceOfLensThicknessDataCodeSequence = new Element(2232626, 'SourceOfLensThicknessDataCodeSequence', 'SQ', '1', '00221132', undefined)
exports.SourceOfAnteriorChamberDepthDataCodeSequence = new Element(2232627, 'SourceOfAnteriorChamberDepthDataCodeSequence', 'SQ', '1', '00221133', undefined)
exports.SourceOfRefractiveMeasurementsSequence = new Element(2232628, 'SourceOfRefractiveMeasurementsSequence', 'SQ', '1', '00221134', undefined)
exports.SourceOfRefractiveMeasurementsCodeSequence = new Element(2232629, 'SourceOfRefractiveMeasurementsCodeSequence', 'SQ', '1', '00221135', undefined)
exports.OphthalmicAxialLengthMeasurementModified = new Element(2232640, 'OphthalmicAxialLengthMeasurementModified', 'CS', '1', '00221140', undefined)
exports.OphthalmicAxialLengthDataSourceCodeSequence = new Element(2232656, 'OphthalmicAxialLengthDataSourceCodeSequence', 'SQ', '1', '00221150', undefined)
exports.OphthalmicAxialLengthAcquisitionMethodCodeSequence = new Element(2232659, 'OphthalmicAxialLengthAcquisitionMethodCodeSequence', 'SQ', '1', '00221153', true)
exports.SignalToNoiseRatio = new Element(2232661, 'SignalToNoiseRatio', 'FL', '1', '00221155', undefined)
exports.OphthalmicAxialLengthDataSourceDescription = new Element(2232665, 'OphthalmicAxialLengthDataSourceDescription', 'LO', '1', '00221159', undefined)
exports.OphthalmicAxialLengthMeasurementsTotalLengthSequence = new Element(2232848, 'OphthalmicAxialLengthMeasurementsTotalLengthSequence', 'SQ', '1', '00221210', undefined)
exports.OphthalmicAxialLengthMeasurementsSegmentalLengthSequence = new Element(2232849, 'OphthalmicAxialLengthMeasurementsSegmentalLengthSequence', 'SQ', '1', '00221211', undefined)
exports.OphthalmicAxialLengthMeasurementsLengthSummationSequence = new Element(2232850, 'OphthalmicAxialLengthMeasurementsLengthSummationSequence', 'SQ', '1', '00221212', undefined)
exports.UltrasoundOphthalmicAxialLengthMeasurementsSequence = new Element(2232864, 'UltrasoundOphthalmicAxialLengthMeasurementsSequence', 'SQ', '1', '00221220', undefined)
exports.OpticalOphthalmicAxialLengthMeasurementsSequence = new Element(2232869, 'OpticalOphthalmicAxialLengthMeasurementsSequence', 'SQ', '1', '00221225', undefined)
exports.UltrasoundSelectedOphthalmicAxialLengthSequence = new Element(2232880, 'UltrasoundSelectedOphthalmicAxialLengthSequence', 'SQ', '1', '00221230', undefined)
exports.OphthalmicAxialLengthSelectionMethodCodeSequence = new Element(2232912, 'OphthalmicAxialLengthSelectionMethodCodeSequence', 'SQ', '1', '00221250', undefined)
exports.OpticalSelectedOphthalmicAxialLengthSequence = new Element(2232917, 'OpticalSelectedOphthalmicAxialLengthSequence', 'SQ', '1', '00221255', undefined)
exports.SelectedSegmentalOphthalmicAxialLengthSequence = new Element(2232919, 'SelectedSegmentalOphthalmicAxialLengthSequence', 'SQ', '1', '00221257', undefined)
exports.SelectedTotalOphthalmicAxialLengthSequence = new Element(2232928, 'SelectedTotalOphthalmicAxialLengthSequence', 'SQ', '1', '00221260', undefined)
exports.OphthalmicAxialLengthQualityMetricSequence = new Element(2232930, 'OphthalmicAxialLengthQualityMetricSequence', 'SQ', '1', '00221262', undefined)
exports.OphthalmicAxialLengthQualityMetricTypeCodeSequence = new Element(2232933, 'OphthalmicAxialLengthQualityMetricTypeCodeSequence', 'SQ', '1', '00221265', true)
exports.OphthalmicAxialLengthQualityMetricTypeDescription = new Element(2232947, 'OphthalmicAxialLengthQualityMetricTypeDescription', 'LO', '1', '00221273', true)
exports.IntraocularLensCalculationsRightEyeSequence = new Element(2233088, 'IntraocularLensCalculationsRightEyeSequence', 'SQ', '1', '00221300', undefined)
exports.IntraocularLensCalculationsLeftEyeSequence = new Element(2233104, 'IntraocularLensCalculationsLeftEyeSequence', 'SQ', '1', '00221310', undefined)
exports.ReferencedOphthalmicAxialLengthMeasurementQCImageSequence = new Element(2233136, 'ReferencedOphthalmicAxialLengthMeasurementQCImageSequence', 'SQ', '1', '00221330', undefined)
exports.OphthalmicMappingDeviceType = new Element(2233365, 'OphthalmicMappingDeviceType', 'CS', '1', '00221415', undefined)
exports.AcquisitionMethodCodeSequence = new Element(2233376, 'AcquisitionMethodCodeSequence', 'SQ', '1', '00221420', undefined)
exports.AcquisitionMethodAlgorithmSequence = new Element(2233379, 'AcquisitionMethodAlgorithmSequence', 'SQ', '1', '00221423', undefined)
exports.OphthalmicThicknessMapTypeCodeSequence = new Element(2233398, 'OphthalmicThicknessMapTypeCodeSequence', 'SQ', '1', '00221436', undefined)
exports.OphthalmicThicknessMappingNormalsSequence = new Element(2233411, 'OphthalmicThicknessMappingNormalsSequence', 'SQ', '1', '00221443', undefined)
exports.RetinalThicknessDefinitionCodeSequence = new Element(2233413, 'RetinalThicknessDefinitionCodeSequence', 'SQ', '1', '00221445', undefined)
exports.PixelValueMappingToCodedConceptSequence = new Element(2233424, 'PixelValueMappingToCodedConceptSequence', 'SQ', '1', '00221450', undefined)
exports.MappedPixelValue = new Element(2233426, 'MappedPixelValue', 'US or SS', '1', '00221452', undefined)
exports.PixelValueMappingExplanation = new Element(2233428, 'PixelValueMappingExplanation', 'LO', '1', '00221454', undefined)
exports.OphthalmicThicknessMapQualityThresholdSequence = new Element(2233432, 'OphthalmicThicknessMapQualityThresholdSequence', 'SQ', '1', '00221458', undefined)
exports.OphthalmicThicknessMapThresholdQualityRating = new Element(2233440, 'OphthalmicThicknessMapThresholdQualityRating', 'FL', '1', '00221460', undefined)
exports.AnatomicStructureReferencePoint = new Element(2233443, 'AnatomicStructureReferencePoint', 'FL', '2', '00221463', undefined)
exports.RegistrationToLocalizerSequence = new Element(2233445, 'RegistrationToLocalizerSequence', 'SQ', '1', '00221465', undefined)
exports.RegisteredLocalizerUnits = new Element(2233446, 'RegisteredLocalizerUnits', 'CS', '1', '00221466', undefined)
exports.RegisteredLocalizerTopLeftHandCorner = new Element(2233447, 'RegisteredLocalizerTopLeftHandCorner', 'FL', '2', '00221467', undefined)
exports.RegisteredLocalizerBottomRightHandCorner = new Element(2233448, 'RegisteredLocalizerBottomRightHandCorner', 'FL', '2', '00221468', undefined)
exports.OphthalmicThicknessMapQualityRatingSequence = new Element(2233456, 'OphthalmicThicknessMapQualityRatingSequence', 'SQ', '1', '00221470', undefined)
exports.RelevantOPTAttributesSequence = new Element(2233458, 'RelevantOPTAttributesSequence', 'SQ', '1', '00221472', undefined)
exports.VisualFieldHorizontalExtent = new Element(2359312, 'VisualFieldHorizontalExtent', 'FL', '1', '00240010', undefined)
exports.VisualFieldVerticalExtent = new Element(2359313, 'VisualFieldVerticalExtent', 'FL', '1', '00240011', undefined)
exports.VisualFieldShape = new Element(2359314, 'VisualFieldShape', 'CS', '1', '00240012', undefined)
exports.ScreeningTestModeCodeSequence = new Element(2359318, 'ScreeningTestModeCodeSequence', 'SQ', '1', '00240016', undefined)
exports.MaximumStimulusLuminance = new Element(2359320, 'MaximumStimulusLuminance', 'FL', '1', '00240018', undefined)
exports.BackgroundLuminance = new Element(2359328, 'BackgroundLuminance', 'FL', '1', '00240020', undefined)
exports.StimulusColorCodeSequence = new Element(2359329, 'StimulusColorCodeSequence', 'SQ', '1', '00240021', undefined)
exports.BackgroundIlluminationColorCodeSequence = new Element(2359332, 'BackgroundIlluminationColorCodeSequence', 'SQ', '1', '00240024', undefined)
exports.StimulusArea = new Element(2359333, 'StimulusArea', 'FL', '1', '00240025', undefined)
exports.StimulusPresentationTime = new Element(2359336, 'StimulusPresentationTime', 'FL', '1', '00240028', undefined)
exports.FixationSequence = new Element(2359346, 'FixationSequence', 'SQ', '1', '00240032', undefined)
exports.FixationMonitoringCodeSequence = new Element(2359347, 'FixationMonitoringCodeSequence', 'SQ', '1', '00240033', undefined)
exports.VisualFieldCatchTrialSequence = new Element(2359348, 'VisualFieldCatchTrialSequence', 'SQ', '1', '00240034', undefined)
exports.FixationCheckedQuantity = new Element(2359349, 'FixationCheckedQuantity', 'US', '1', '00240035', undefined)
exports.PatientNotProperlyFixatedQuantity = new Element(2359350, 'PatientNotProperlyFixatedQuantity', 'US', '1', '00240036', undefined)
exports.PresentedVisualStimuliDataFlag = new Element(2359351, 'PresentedVisualStimuliDataFlag', 'CS', '1', '00240037', undefined)
exports.NumberOfVisualStimuli = new Element(2359352, 'NumberOfVisualStimuli', 'US', '1', '00240038', undefined)
exports.ExcessiveFixationLossesDataFlag = new Element(2359353, 'ExcessiveFixationLossesDataFlag', 'CS', '1', '00240039', undefined)
exports.ExcessiveFixationLosses = new Element(2359360, 'ExcessiveFixationLosses', 'CS', '1', '00240040', undefined)
exports.StimuliRetestingQuantity = new Element(2359362, 'StimuliRetestingQuantity', 'US', '1', '00240042', undefined)
exports.CommentsOnPatientPerformanceOfVisualField = new Element(2359364, 'CommentsOnPatientPerformanceOfVisualField', 'LT', '1', '00240044', undefined)
exports.FalseNegativesEstimateFlag = new Element(2359365, 'FalseNegativesEstimateFlag', 'CS', '1', '00240045', undefined)
exports.FalseNegativesEstimate = new Element(2359366, 'FalseNegativesEstimate', 'FL', '1', '00240046', undefined)
exports.NegativeCatchTrialsQuantity = new Element(2359368, 'NegativeCatchTrialsQuantity', 'US', '1', '00240048', undefined)
exports.FalseNegativesQuantity = new Element(2359376, 'FalseNegativesQuantity', 'US', '1', '00240050', undefined)
exports.ExcessiveFalseNegativesDataFlag = new Element(2359377, 'ExcessiveFalseNegativesDataFlag', 'CS', '1', '00240051', undefined)
exports.ExcessiveFalseNegatives = new Element(2359378, 'ExcessiveFalseNegatives', 'CS', '1', '00240052', undefined)
exports.FalsePositivesEstimateFlag = new Element(2359379, 'FalsePositivesEstimateFlag', 'CS', '1', '00240053', undefined)
exports.FalsePositivesEstimate = new Element(2359380, 'FalsePositivesEstimate', 'FL', '1', '00240054', undefined)
exports.CatchTrialsDataFlag = new Element(2359381, 'CatchTrialsDataFlag', 'CS', '1', '00240055', undefined)
exports.PositiveCatchTrialsQuantity = new Element(2359382, 'PositiveCatchTrialsQuantity', 'US', '1', '00240056', undefined)
exports.TestPointNormalsDataFlag = new Element(2359383, 'TestPointNormalsDataFlag', 'CS', '1', '00240057', undefined)
exports.TestPointNormalsSequence = new Element(2359384, 'TestPointNormalsSequence', 'SQ', '1', '00240058', undefined)
exports.GlobalDeviationProbabilityNormalsFlag = new Element(2359385, 'GlobalDeviationProbabilityNormalsFlag', 'CS', '1', '00240059', undefined)
exports.FalsePositivesQuantity = new Element(2359392, 'FalsePositivesQuantity', 'US', '1', '00240060', undefined)
exports.ExcessiveFalsePositivesDataFlag = new Element(2359393, 'ExcessiveFalsePositivesDataFlag', 'CS', '1', '00240061', undefined)
exports.ExcessiveFalsePositives = new Element(2359394, 'ExcessiveFalsePositives', 'CS', '1', '00240062', undefined)
exports.VisualFieldTestNormalsFlag = new Element(2359395, 'VisualFieldTestNormalsFlag', 'CS', '1', '00240063', undefined)
exports.ResultsNormalsSequence = new Element(2359396, 'ResultsNormalsSequence', 'SQ', '1', '00240064', undefined)
exports.AgeCorrectedSensitivityDeviationAlgorithmSequence = new Element(2359397, 'AgeCorrectedSensitivityDeviationAlgorithmSequence', 'SQ', '1', '00240065', undefined)
exports.GlobalDeviationFromNormal = new Element(2359398, 'GlobalDeviationFromNormal', 'FL', '1', '00240066', undefined)
exports.GeneralizedDefectSensitivityDeviationAlgorithmSequence = new Element(2359399, 'GeneralizedDefectSensitivityDeviationAlgorithmSequence', 'SQ', '1', '00240067', undefined)
exports.LocalizedDeviationFromNormal = new Element(2359400, 'LocalizedDeviationFromNormal', 'FL', '1', '00240068', undefined)
exports.PatientReliabilityIndicator = new Element(2359401, 'PatientReliabilityIndicator', 'LO', '1', '00240069', undefined)
exports.VisualFieldMeanSensitivity = new Element(2359408, 'VisualFieldMeanSensitivity', 'FL', '1', '00240070', undefined)
exports.GlobalDeviationProbability = new Element(2359409, 'GlobalDeviationProbability', 'FL', '1', '00240071', undefined)
exports.LocalDeviationProbabilityNormalsFlag = new Element(2359410, 'LocalDeviationProbabilityNormalsFlag', 'CS', '1', '00240072', undefined)
exports.LocalizedDeviationProbability = new Element(2359411, 'LocalizedDeviationProbability', 'FL', '1', '00240073', undefined)
exports.ShortTermFluctuationCalculated = new Element(2359412, 'ShortTermFluctuationCalculated', 'CS', '1', '00240074', undefined)
exports.ShortTermFluctuation = new Element(2359413, 'ShortTermFluctuation', 'FL', '1', '00240075', undefined)
exports.ShortTermFluctuationProbabilityCalculated = new Element(2359414, 'ShortTermFluctuationProbabilityCalculated', 'CS', '1', '00240076', undefined)
exports.ShortTermFluctuationProbability = new Element(2359415, 'ShortTermFluctuationProbability', 'FL', '1', '00240077', undefined)
exports.CorrectedLocalizedDeviationFromNormalCalculated = new Element(2359416, 'CorrectedLocalizedDeviationFromNormalCalculated', 'CS', '1', '00240078', undefined)
exports.CorrectedLocalizedDeviationFromNormal = new Element(2359417, 'CorrectedLocalizedDeviationFromNormal', 'FL', '1', '00240079', undefined)
exports.CorrectedLocalizedDeviationFromNormalProbabilityCalculated = new Element(2359424, 'CorrectedLocalizedDeviationFromNormalProbabilityCalculated', 'CS', '1', '00240080', undefined)
exports.CorrectedLocalizedDeviationFromNormalProbability = new Element(2359425, 'CorrectedLocalizedDeviationFromNormalProbability', 'FL', '1', '00240081', undefined)
exports.GlobalDeviationProbabilitySequence = new Element(2359427, 'GlobalDeviationProbabilitySequence', 'SQ', '1', '00240083', undefined)
exports.LocalizedDeviationProbabilitySequence = new Element(2359429, 'LocalizedDeviationProbabilitySequence', 'SQ', '1', '00240085', undefined)
exports.FovealSensitivityMeasured = new Element(2359430, 'FovealSensitivityMeasured', 'CS', '1', '00240086', undefined)
exports.FovealSensitivity = new Element(2359431, 'FovealSensitivity', 'FL', '1', '00240087', undefined)
exports.VisualFieldTestDuration = new Element(2359432, 'VisualFieldTestDuration', 'FL', '1', '00240088', undefined)
exports.VisualFieldTestPointSequence = new Element(2359433, 'VisualFieldTestPointSequence', 'SQ', '1', '00240089', undefined)
exports.VisualFieldTestPointXCoordinate = new Element(2359440, 'VisualFieldTestPointXCoordinate', 'FL', '1', '00240090', undefined)
exports.VisualFieldTestPointYCoordinate = new Element(2359441, 'VisualFieldTestPointYCoordinate', 'FL', '1', '00240091', undefined)
exports.AgeCorrectedSensitivityDeviationValue = new Element(2359442, 'AgeCorrectedSensitivityDeviationValue', 'FL', '1', '00240092', undefined)
exports.StimulusResults = new Element(2359443, 'StimulusResults', 'CS', '1', '00240093', undefined)
exports.SensitivityValue = new Element(2359444, 'SensitivityValue', 'FL', '1', '00240094', undefined)
exports.RetestStimulusSeen = new Element(2359445, 'RetestStimulusSeen', 'CS', '1', '00240095', undefined)
exports.RetestSensitivityValue = new Element(2359446, 'RetestSensitivityValue', 'FL', '1', '00240096', undefined)
exports.VisualFieldTestPointNormalsSequence = new Element(2359447, 'VisualFieldTestPointNormalsSequence', 'SQ', '1', '00240097', undefined)
exports.QuantifiedDefect = new Element(2359448, 'QuantifiedDefect', 'FL', '1', '00240098', undefined)
exports.AgeCorrectedSensitivityDeviationProbabilityValue = new Element(2359552, 'AgeCorrectedSensitivityDeviationProbabilityValue', 'FL', '1', '00240100', undefined)
exports.GeneralizedDefectCorrectedSensitivityDeviationFlag = new Element(2359554, 'GeneralizedDefectCorrectedSensitivityDeviationFlag', 'CS', '1', '00240102', undefined)
exports.GeneralizedDefectCorrectedSensitivityDeviationValue = new Element(2359555, 'GeneralizedDefectCorrectedSensitivityDeviationValue', 'FL', '1', '00240103', undefined)
exports.GeneralizedDefectCorrectedSensitivityDeviationProbabilityValue = new Element(2359556, 'GeneralizedDefectCorrectedSensitivityDeviationProbabilityValue', 'FL', '1', '00240104', undefined)
exports.MinimumSensitivityValue = new Element(2359557, 'MinimumSensitivityValue', 'FL', '1', '00240105', undefined)
exports.BlindSpotLocalized = new Element(2359558, 'BlindSpotLocalized', 'CS', '1', '00240106', undefined)
exports.BlindSpotXCoordinate = new Element(2359559, 'BlindSpotXCoordinate', 'FL', '1', '00240107', undefined)
exports.BlindSpotYCoordinate = new Element(2359560, 'BlindSpotYCoordinate', 'FL', '1', '00240108', undefined)
exports.VisualAcuityMeasurementSequence = new Element(2359568, 'VisualAcuityMeasurementSequence', 'SQ', '1', '00240110', undefined)
exports.RefractiveParametersUsedOnPatientSequence = new Element(2359570, 'RefractiveParametersUsedOnPatientSequence', 'SQ', '1', '00240112', undefined)
exports.MeasurementLaterality = new Element(2359571, 'MeasurementLaterality', 'CS', '1', '00240113', undefined)
exports.OphthalmicPatientClinicalInformationLeftEyeSequence = new Element(2359572, 'OphthalmicPatientClinicalInformationLeftEyeSequence', 'SQ', '1', '00240114', undefined)
exports.OphthalmicPatientClinicalInformationRightEyeSequence = new Element(2359573, 'OphthalmicPatientClinicalInformationRightEyeSequence', 'SQ', '1', '00240115', undefined)
exports.FovealPointNormativeDataFlag = new Element(2359575, 'FovealPointNormativeDataFlag', 'CS', '1', '00240117', undefined)
exports.FovealPointProbabilityValue = new Element(2359576, 'FovealPointProbabilityValue', 'FL', '1', '00240118', undefined)
exports.ScreeningBaselineMeasured = new Element(2359584, 'ScreeningBaselineMeasured', 'CS', '1', '00240120', undefined)
exports.ScreeningBaselineMeasuredSequence = new Element(2359586, 'ScreeningBaselineMeasuredSequence', 'SQ', '1', '00240122', undefined)
exports.ScreeningBaselineType = new Element(2359588, 'ScreeningBaselineType', 'CS', '1', '00240124', undefined)
exports.ScreeningBaselineValue = new Element(2359590, 'ScreeningBaselineValue', 'FL', '1', '00240126', undefined)
exports.AlgorithmSource = new Element(2359810, 'AlgorithmSource', 'LO', '1', '00240202', undefined)
exports.DataSetName = new Element(2360070, 'DataSetName', 'LO', '1', '00240306', undefined)
exports.DataSetVersion = new Element(2360071, 'DataSetVersion', 'LO', '1', '00240307', undefined)
exports.DataSetSource = new Element(2360072, 'DataSetSource', 'LO', '1', '00240308', undefined)
exports.DataSetDescription = new Element(2360073, 'DataSetDescription', 'LO', '1', '00240309', undefined)
exports.VisualFieldTestReliabilityGlobalIndexSequence = new Element(2360087, 'VisualFieldTestReliabilityGlobalIndexSequence', 'SQ', '1', '00240317', undefined)
exports.VisualFieldGlobalResultsIndexSequence = new Element(2360096, 'VisualFieldGlobalResultsIndexSequence', 'SQ', '1', '00240320', undefined)
exports.DataObservationSequence = new Element(2360101, 'DataObservationSequence', 'SQ', '1', '00240325', undefined)
exports.IndexNormalsFlag = new Element(2360120, 'IndexNormalsFlag', 'CS', '1', '00240338', undefined)
exports.IndexProbability = new Element(2360129, 'IndexProbability', 'FL', '1', '00240341', undefined)
exports.IndexProbabilitySequence = new Element(2360132, 'IndexProbabilitySequence', 'SQ', '1', '00240344', undefined)
exports.SamplesPerPixel = new Element(2621442, 'SamplesPerPixel', 'US', '1', '00280002', undefined)
exports.SamplesPerPixelUsed = new Element(2621443, 'SamplesPerPixelUsed', 'US', '1', '00280003', undefined)
exports.PhotometricInterpretation = new Element(2621444, 'PhotometricInterpretation', 'CS', '1', '00280004', undefined)
exports.ImageDimensions = new Element(2621445, 'ImageDimensions', 'US', '1', '00280005', true)
exports.PlanarConfiguration = new Element(2621446, 'PlanarConfiguration', 'US', '1', '00280006', undefined)
exports.NumberOfFrames = new Element(2621448, 'NumberOfFrames', 'IS', '1', '00280008', undefined)
exports.FrameIncrementPointer = new Element(2621449, 'FrameIncrementPointer', 'AT', '1-n', '00280009', undefined)
exports.FrameDimensionPointer = new Element(2621450, 'FrameDimensionPointer', 'AT', '1-n', '0028000A', undefined)
exports.Rows = new Element(2621456, 'Rows', 'US', '1', '00280010', undefined)
exports.Columns = new Element(2621457, 'Columns', 'US', '1', '00280011', undefined)
exports.Planes = new Element(2621458, 'Planes', 'US', '1', '00280012', true)
exports.UltrasoundColorDataPresent = new Element(2621460, 'UltrasoundColorDataPresent', 'US', '1', '00280014', undefined)
exports.PixelSpacing = new Element(2621488, 'PixelSpacing', 'DS', '2', '00280030', undefined)
exports.ZoomFactor = new Element(2621489, 'ZoomFactor', 'DS', '2', '00280031', undefined)
exports.ZoomCenter = new Element(2621490, 'ZoomCenter', 'DS', '2', '00280032', undefined)
exports.PixelAspectRatio = new Element(2621492, 'PixelAspectRatio', 'IS', '2', '00280034', undefined)
exports.ImageFormat = new Element(2621504, 'ImageFormat', 'CS', '1', '00280040', true)
exports.ManipulatedImage = new Element(2621520, 'ManipulatedImage', 'LO', '1-n', '00280050', true)
exports.CorrectedImage = new Element(2621521, 'CorrectedImage', 'CS', '1-n', '00280051', undefined)
exports.CompressionRecognitionCode = new Element(2621535, 'CompressionRecognitionCode', 'LO', '1', '0028005F', true)
exports.CompressionCode = new Element(2621536, 'CompressionCode', 'CS', '1', '00280060', true)
exports.CompressionOriginator = new Element(2621537, 'CompressionOriginator', 'SH', '1', '00280061', true)
exports.CompressionLabel = new Element(2621538, 'CompressionLabel', 'LO', '1', '00280062', true)
exports.CompressionDescription = new Element(2621539, 'CompressionDescription', 'SH', '1', '00280063', true)
exports.CompressionSequence = new Element(2621541, 'CompressionSequence', 'CS', '1-n', '00280065', true)
exports.CompressionStepPointers = new Element(2621542, 'CompressionStepPointers', 'AT', '1-n', '00280066', true)
exports.RepeatInterval = new Element(2621544, 'RepeatInterval', 'US', '1', '00280068', true)
exports.BitsGrouped = new Element(2621545, 'BitsGrouped', 'US', '1', '00280069', true)
exports.PerimeterTable = new Element(2621552, 'PerimeterTable', 'US', '1-n', '00280070', true)
exports.PerimeterValue = new Element(2621553, 'PerimeterValue', 'US or SS', '1', '00280071', true)
exports.PredictorRows = new Element(2621568, 'PredictorRows', 'US', '1', '00280080', true)
exports.PredictorColumns = new Element(2621569, 'PredictorColumns', 'US', '1', '00280081', true)
exports.PredictorConstants = new Element(2621570, 'PredictorConstants', 'US', '1-n', '00280082', true)
exports.BlockedPixels = new Element(2621584, 'BlockedPixels', 'CS', '1', '00280090', true)
exports.BlockRows = new Element(2621585, 'BlockRows', 'US', '1', '00280091', true)
exports.BlockColumns = new Element(2621586, 'BlockColumns', 'US', '1', '00280092', true)
exports.RowOverlap = new Element(2621587, 'RowOverlap', 'US', '1', '00280093', true)
exports.ColumnOverlap = new Element(2621588, 'ColumnOverlap', 'US', '1', '00280094', true)
exports.BitsAllocated = new Element(2621696, 'BitsAllocated', 'US', '1', '00280100', undefined)
exports.BitsStored = new Element(2621697, 'BitsStored', 'US', '1', '00280101', undefined)
exports.HighBit = new Element(2621698, 'HighBit', 'US', '1', '00280102', undefined)
exports.PixelRepresentation = new Element(2621699, 'PixelRepresentation', 'US', '1', '00280103', undefined)
exports.SmallestValidPixelValue = new Element(2621700, 'SmallestValidPixelValue', 'US or SS', '1', '00280104', true)
exports.LargestValidPixelValue = new Element(2621701, 'LargestValidPixelValue', 'US or SS', '1', '00280105', true)
exports.SmallestImagePixelValue = new Element(2621702, 'SmallestImagePixelValue', 'US or SS', '1', '00280106', undefined)
exports.LargestImagePixelValue = new Element(2621703, 'LargestImagePixelValue', 'US or SS', '1', '00280107', undefined)
exports.SmallestPixelValueInSeries = new Element(2621704, 'SmallestPixelValueInSeries', 'US or SS', '1', '00280108', undefined)
exports.LargestPixelValueInSeries = new Element(2621705, 'LargestPixelValueInSeries', 'US or SS', '1', '00280109', undefined)
exports.SmallestImagePixelValueInPlane = new Element(2621712, 'SmallestImagePixelValueInPlane', 'US or SS', '1', '00280110', true)
exports.LargestImagePixelValueInPlane = new Element(2621713, 'LargestImagePixelValueInPlane', 'US or SS', '1', '00280111', true)
exports.PixelPaddingValue = new Element(2621728, 'PixelPaddingValue', 'US or SS', '1', '00280120', undefined)
exports.PixelPaddingRangeLimit = new Element(2621729, 'PixelPaddingRangeLimit', 'US or SS', '1', '00280121', undefined)
exports.ImageLocation = new Element(2621952, 'ImageLocation', 'US', '1', '00280200', true)
exports.QualityControlImage = new Element(2622208, 'QualityControlImage', 'CS', '1', '00280300', undefined)
exports.BurnedInAnnotation = new Element(2622209, 'BurnedInAnnotation', 'CS', '1', '00280301', undefined)
exports.RecognizableVisualFeatures = new Element(2622210, 'RecognizableVisualFeatures', 'CS', '1', '00280302', undefined)
exports.LongitudinalTemporalInformationModified = new Element(2622211, 'LongitudinalTemporalInformationModified', 'CS', '1', '00280303', undefined)
exports.ReferencedColorPaletteInstanceUID = new Element(2622212, 'ReferencedColorPaletteInstanceUID', 'UI', '1', '00280304', undefined)
exports.TransformLabel = new Element(2622464, 'TransformLabel', 'LO', '1', '00280400', true)
exports.TransformVersionNumber = new Element(2622465, 'TransformVersionNumber', 'LO', '1', '00280401', true)
exports.NumberOfTransformSteps = new Element(2622466, 'NumberOfTransformSteps', 'US', '1', '00280402', true)
exports.SequenceOfCompressedData = new Element(2622467, 'SequenceOfCompressedData', 'LO', '1-n', '00280403', true)
exports.DetailsOfCoefficients = new Element(2622468, 'DetailsOfCoefficients', 'AT', '1-n', '00280404', true)
exports.RowsForNthOrderCoefficients = new Element(2622464, 'RowsForNthOrderCoefficients', 'US', '1', '002804x0', true)
exports.ColumnsForNthOrderCoefficients = new Element(2622465, 'ColumnsForNthOrderCoefficients', 'US', '1', '002804x1', true)
exports.CoefficientCoding = new Element(2622466, 'CoefficientCoding', 'LO', '1-n', '002804x2', true)
exports.CoefficientCodingPointers = new Element(2622467, 'CoefficientCodingPointers', 'AT', '1-n', '002804x3', true)
exports.DCTLabel = new Element(2623232, 'DCTLabel', 'LO', '1', '00280700', true)
exports.DataBlockDescription = new Element(2623233, 'DataBlockDescription', 'CS', '1-n', '00280701', true)
exports.DataBlock = new Element(2623234, 'DataBlock', 'AT', '1-n', '00280702', true)
exports.NormalizationFactorFormat = new Element(2623248, 'NormalizationFactorFormat', 'US', '1', '00280710', true)
exports.ZonalMapNumberFormat = new Element(2623264, 'ZonalMapNumberFormat', 'US', '1', '00280720', true)
exports.ZonalMapLocation = new Element(2623265, 'ZonalMapLocation', 'AT', '1-n', '00280721', true)
exports.ZonalMapFormat = new Element(2623266, 'ZonalMapFormat', 'US', '1', '00280722', true)
exports.AdaptiveMapFormat = new Element(2623280, 'AdaptiveMapFormat', 'US', '1', '00280730', true)
exports.CodeNumberFormat = new Element(2623296, 'CodeNumberFormat', 'US', '1', '00280740', true)
exports.CodeLabel = new Element(2623488, 'CodeLabel', 'CS', '1-n', '002808x0', true)
exports.NumberOfTables = new Element(2623490, 'NumberOfTables', 'US', '1', '002808x2', true)
exports.CodeTableLocation = new Element(2623491, 'CodeTableLocation', 'AT', '1-n', '002808x3', true)
exports.BitsForCodeWord = new Element(2623492, 'BitsForCodeWord', 'US', '1', '002808x4', true)
exports.ImageDataLocation = new Element(2623496, 'ImageDataLocation', 'AT', '1-n', '002808x8', true)
exports.PixelSpacingCalibrationType = new Element(2624002, 'PixelSpacingCalibrationType', 'CS', '1', '00280A02', undefined)
exports.PixelSpacingCalibrationDescription = new Element(2624004, 'PixelSpacingCalibrationDescription', 'LO', '1', '00280A04', undefined)
exports.PixelIntensityRelationship = new Element(2625600, 'PixelIntensityRelationship', 'CS', '1', '00281040', undefined)
exports.PixelIntensityRelationshipSign = new Element(2625601, 'PixelIntensityRelationshipSign', 'SS', '1', '00281041', undefined)
exports.WindowCenter = new Element(2625616, 'WindowCenter', 'DS', '1-n', '00281050', undefined)
exports.WindowWidth = new Element(2625617, 'WindowWidth', 'DS', '1-n', '00281051', undefined)
exports.RescaleIntercept = new Element(2625618, 'RescaleIntercept', 'DS', '1', '00281052', undefined)
exports.RescaleSlope = new Element(2625619, 'RescaleSlope', 'DS', '1', '00281053', undefined)
exports.RescaleType = new Element(2625620, 'RescaleType', 'LO', '1', '00281054', undefined)
exports.WindowCenterWidthExplanation = new Element(2625621, 'WindowCenterWidthExplanation', 'LO', '1-n', '00281055', undefined)
exports.VOILUTFunction = new Element(2625622, 'VOILUTFunction', 'CS', '1', '00281056', undefined)
exports.GrayScale = new Element(2625664, 'GrayScale', 'CS', '1', '00281080', true)
exports.RecommendedViewingMode = new Element(2625680, 'RecommendedViewingMode', 'CS', '1', '00281090', undefined)
exports.GrayLookupTableDescriptor = new Element(2625792, 'GrayLookupTableDescriptor', 'US or SS', '3', '00281100', true)
exports.RedPaletteColorLookupTableDescriptor = new Element(2625793, 'RedPaletteColorLookupTableDescriptor', 'US or SS', '3', '00281101', undefined)
exports.GreenPaletteColorLookupTableDescriptor = new Element(2625794, 'GreenPaletteColorLookupTableDescriptor', 'US or SS', '3', '00281102', undefined)
exports.BluePaletteColorLookupTableDescriptor = new Element(2625795, 'BluePaletteColorLookupTableDescriptor', 'US or SS', '3', '00281103', undefined)
exports.AlphaPaletteColorLookupTableDescriptor = new Element(2625796, 'AlphaPaletteColorLookupTableDescriptor', 'US', '3', '00281104', undefined)
exports.LargeRedPaletteColorLookupTableDescriptor = new Element(2625809, 'LargeRedPaletteColorLookupTableDescriptor', 'US or SS', '4', '00281111', true)
exports.LargeGreenPaletteColorLookupTableDescriptor = new Element(2625810, 'LargeGreenPaletteColorLookupTableDescriptor', 'US or SS', '4', '00281112', true)
exports.LargeBluePaletteColorLookupTableDescriptor = new Element(2625811, 'LargeBluePaletteColorLookupTableDescriptor', 'US or SS', '4', '00281113', true)
exports.PaletteColorLookupTableUID = new Element(2625945, 'PaletteColorLookupTableUID', 'UI', '1', '00281199', undefined)
exports.GrayLookupTableData = new Element(2626048, 'GrayLookupTableData', 'US or SS or OW', '1-n or 1', '00281200', true)
exports.RedPaletteColorLookupTableData = new Element(2626049, 'RedPaletteColorLookupTableData', 'OW', '1', '00281201', undefined)
exports.GreenPaletteColorLookupTableData = new Element(2626050, 'GreenPaletteColorLookupTableData', 'OW', '1', '00281202', undefined)
exports.BluePaletteColorLookupTableData = new Element(2626051, 'BluePaletteColorLookupTableData', 'OW', '1', '00281203', undefined)
exports.AlphaPaletteColorLookupTableData = new Element(2626052, 'AlphaPaletteColorLookupTableData', 'OW', '1', '00281204', undefined)
exports.LargeRedPaletteColorLookupTableData = new Element(2626065, 'LargeRedPaletteColorLookupTableData', 'OW', '1', '00281211', true)
exports.LargeGreenPaletteColorLookupTableData = new Element(2626066, 'LargeGreenPaletteColorLookupTableData', 'OW', '1', '00281212', true)
exports.LargeBluePaletteColorLookupTableData = new Element(2626067, 'LargeBluePaletteColorLookupTableData', 'OW', '1', '00281213', true)
exports.LargePaletteColorLookupTableUID = new Element(2626068, 'LargePaletteColorLookupTableUID', 'UI', '1', '00281214', true)
exports.SegmentedRedPaletteColorLookupTableData = new Element(2626081, 'SegmentedRedPaletteColorLookupTableData', 'OW', '1', '00281221', undefined)
exports.SegmentedGreenPaletteColorLookupTableData = new Element(2626082, 'SegmentedGreenPaletteColorLookupTableData', 'OW', '1', '00281222', undefined)
exports.SegmentedBluePaletteColorLookupTableData = new Element(2626083, 'SegmentedBluePaletteColorLookupTableData', 'OW', '1', '00281223', undefined)
exports.BreastImplantPresent = new Element(2626304, 'BreastImplantPresent', 'CS', '1', '00281300', undefined)
exports.PartialView = new Element(2626384, 'PartialView', 'CS', '1', '00281350', undefined)
exports.PartialViewDescription = new Element(2626385, 'PartialViewDescription', 'ST', '1', '00281351', undefined)
exports.PartialViewCodeSequence = new Element(2626386, 'PartialViewCodeSequence', 'SQ', '1', '00281352', undefined)
exports.SpatialLocationsPreserved = new Element(2626394, 'SpatialLocationsPreserved', 'CS', '1', '0028135A', undefined)
exports.DataFrameAssignmentSequence = new Element(2626561, 'DataFrameAssignmentSequence', 'SQ', '1', '00281401', undefined)
exports.DataPathAssignment = new Element(2626562, 'DataPathAssignment', 'CS', '1', '00281402', undefined)
exports.BitsMappedToColorLookupTable = new Element(2626563, 'BitsMappedToColorLookupTable', 'US', '1', '00281403', undefined)
exports.BlendingLUT1Sequence = new Element(2626564, 'BlendingLUT1Sequence', 'SQ', '1', '00281404', undefined)
exports.BlendingLUT1TransferFunction = new Element(2626565, 'BlendingLUT1TransferFunction', 'CS', '1', '00281405', undefined)
exports.BlendingWeightConstant = new Element(2626566, 'BlendingWeightConstant', 'FD', '1', '00281406', undefined)
exports.BlendingLookupTableDescriptor = new Element(2626567, 'BlendingLookupTableDescriptor', 'US', '3', '00281407', undefined)
exports.BlendingLookupTableData = new Element(2626568, 'BlendingLookupTableData', 'OW', '1', '00281408', undefined)
exports.EnhancedPaletteColorLookupTableSequence = new Element(2626571, 'EnhancedPaletteColorLookupTableSequence', 'SQ', '1', '0028140B', undefined)
exports.BlendingLUT2Sequence = new Element(2626572, 'BlendingLUT2Sequence', 'SQ', '1', '0028140C', undefined)
exports.BlendingLUT2TransferFunction = new Element(2626573, 'BlendingLUT2TransferFunction', 'CS', '1', '0028140D', undefined)
exports.DataPathID = new Element(2626574, 'DataPathID', 'CS', '1', '0028140E', undefined)
exports.RGBLUTTransferFunction = new Element(2626575, 'RGBLUTTransferFunction', 'CS', '1', '0028140F', undefined)
exports.AlphaLUTTransferFunction = new Element(2626576, 'AlphaLUTTransferFunction', 'CS', '1', '00281410', undefined)
exports.ICCProfile = new Element(2629632, 'ICCProfile', 'OB', '1', '00282000', undefined)
exports.LossyImageCompression = new Element(2629904, 'LossyImageCompression', 'CS', '1', '00282110', undefined)
exports.LossyImageCompressionRatio = new Element(2629906, 'LossyImageCompressionRatio', 'DS', '1-n', '00282112', undefined)
exports.LossyImageCompressionMethod = new Element(2629908, 'LossyImageCompressionMethod', 'CS', '1-n', '00282114', undefined)
exports.ModalityLUTSequence = new Element(2633728, 'ModalityLUTSequence', 'SQ', '1', '00283000', undefined)
exports.LUTDescriptor = new Element(2633730, 'LUTDescriptor', 'US or SS', '3', '00283002', undefined)
exports.LUTExplanation = new Element(2633731, 'LUTExplanation', 'LO', '1', '00283003', undefined)
exports.ModalityLUTType = new Element(2633732, 'ModalityLUTType', 'LO', '1', '00283004', undefined)
exports.LUTData = new Element(2633734, 'LUTData', 'US or OW', '1-n or 1', '00283006', undefined)
exports.VOILUTSequence = new Element(2633744, 'VOILUTSequence', 'SQ', '1', '00283010', undefined)
exports.SoftcopyVOILUTSequence = new Element(2634000, 'SoftcopyVOILUTSequence', 'SQ', '1', '00283110', undefined)
exports.ImagePresentationComments = new Element(2637824, 'ImagePresentationComments', 'LT', '1', '00284000', true)
exports.BiPlaneAcquisitionSequence = new Element(2641920, 'BiPlaneAcquisitionSequence', 'SQ', '1', '00285000', true)
exports.RepresentativeFrameNumber = new Element(2646032, 'RepresentativeFrameNumber', 'US', '1', '00286010', undefined)
exports.FrameNumbersOfInterest = new Element(2646048, 'FrameNumbersOfInterest', 'US', '1-n', '00286020', undefined)
exports.FrameOfInterestDescription = new Element(2646050, 'FrameOfInterestDescription', 'LO', '1-n', '00286022', undefined)
exports.FrameOfInterestType = new Element(2646051, 'FrameOfInterestType', 'CS', '1-n', '00286023', undefined)
exports.MaskPointers = new Element(2646064, 'MaskPointers', 'US', '1-n', '00286030', true)
exports.RWavePointer = new Element(2646080, 'RWavePointer', 'US', '1-n', '00286040', undefined)
exports.MaskSubtractionSequence = new Element(2646272, 'MaskSubtractionSequence', 'SQ', '1', '00286100', undefined)
exports.MaskOperation = new Element(2646273, 'MaskOperation', 'CS', '1', '00286101', undefined)
exports.ApplicableFrameRange = new Element(2646274, 'ApplicableFrameRange', 'US', '2-2n', '00286102', undefined)
exports.MaskFrameNumbers = new Element(2646288, 'MaskFrameNumbers', 'US', '1-n', '00286110', undefined)
exports.ContrastFrameAveraging = new Element(2646290, 'ContrastFrameAveraging', 'US', '1', '00286112', undefined)
exports.MaskSubPixelShift = new Element(2646292, 'MaskSubPixelShift', 'FL', '2', '00286114', undefined)
exports.TIDOffset = new Element(2646304, 'TIDOffset', 'SS', '1', '00286120', undefined)
exports.MaskOperationExplanation = new Element(2646416, 'MaskOperationExplanation', 'ST', '1', '00286190', undefined)
exports.EquipmentAdministratorSequence = new Element(2650112, 'EquipmentAdministratorSequence', 'SQ', '1', '00287000', undefined)
exports.NumberOfDisplaySubsystems = new Element(2650113, 'NumberOfDisplaySubsystems', 'US', '1', '00287001', undefined)
exports.CurrentConfigurationID = new Element(2650114, 'CurrentConfigurationID', 'US', '1', '00287002', undefined)
exports.DisplaySubsystemID = new Element(2650115, 'DisplaySubsystemID', 'US', '1', '00287003', undefined)
exports.DisplaySubsystemName = new Element(2650116, 'DisplaySubsystemName', 'SH', '1', '00287004', undefined)
exports.DisplaySubsystemDescription = new Element(2650117, 'DisplaySubsystemDescription', 'LO', '1', '00287005', undefined)
exports.SystemStatus = new Element(2650118, 'SystemStatus', 'CS', '1', '00287006', undefined)
exports.SystemStatusComment = new Element(2650119, 'SystemStatusComment', 'LO', '1', '00287007', undefined)
exports.TargetLuminanceCharacteristicsSequence = new Element(2650120, 'TargetLuminanceCharacteristicsSequence', 'SQ', '1', '00287008', undefined)
exports.LuminanceCharacteristicsID = new Element(2650121, 'LuminanceCharacteristicsID', 'US', '1', '00287009', undefined)
exports.DisplaySubsystemConfigurationSequence = new Element(2650122, 'DisplaySubsystemConfigurationSequence', 'SQ', '1', '0028700A', undefined)
exports.ConfigurationID = new Element(2650123, 'ConfigurationID', 'US', '1', '0028700B', undefined)
exports.ConfigurationName = new Element(2650124, 'ConfigurationName', 'SH', '1', '0028700C', undefined)
exports.ConfigurationDescription = new Element(2650125, 'ConfigurationDescription', 'LO', '1', '0028700D', undefined)
exports.ReferencedTargetLuminanceCharacteristicsID = new Element(2650126, 'ReferencedTargetLuminanceCharacteristicsID', 'US', '1', '0028700E', undefined)
exports.QAResultsSequence = new Element(2650127, 'QAResultsSequence', 'SQ', '1', '0028700F', undefined)
exports.DisplaySubsystemQAResultsSequence = new Element(2650128, 'DisplaySubsystemQAResultsSequence', 'SQ', '1', '00287010', undefined)
exports.ConfigurationQAResultsSequence = new Element(2650129, 'ConfigurationQAResultsSequence', 'SQ', '1', '00287011', undefined)
exports.MeasurementEquipmentSequence = new Element(2650130, 'MeasurementEquipmentSequence', 'SQ', '1', '00287012', undefined)
exports.MeasurementFunctions = new Element(2650131, 'MeasurementFunctions', 'CS', '1-n', '00287013', undefined)
exports.MeasurementEquipmentType = new Element(2650132, 'MeasurementEquipmentType', 'CS', '1', '00287014', undefined)
exports.VisualEvaluationResultSequence = new Element(2650133, 'VisualEvaluationResultSequence', 'SQ', '1', '00287015', undefined)
exports.DisplayCalibrationResultSequence = new Element(2650134, 'DisplayCalibrationResultSequence', 'SQ', '1', '00287016', undefined)
exports.DDLValue = new Element(2650135, 'DDLValue', 'US', '1', '00287017', undefined)
exports.CIExyWhitePoint = new Element(2650136, 'CIExyWhitePoint', 'FL', '2', '00287018', undefined)
exports.DisplayFunctionType = new Element(2650137, 'DisplayFunctionType', 'CS', '1', '00287019', undefined)
exports.GammaValue = new Element(2650138, 'GammaValue', 'FL', '1', '0028701A', undefined)
exports.NumberOfLuminancePoints = new Element(2650139, 'NumberOfLuminancePoints', 'US', '1', '0028701B', undefined)
exports.LuminanceResponseSequence = new Element(2650140, 'LuminanceResponseSequence', 'SQ', '1', '0028701C', undefined)
exports.TargetMinimumLuminance = new Element(2650141, 'TargetMinimumLuminance', 'FL', '1', '0028701D', undefined)
exports.TargetMaximumLuminance = new Element(2650142, 'TargetMaximumLuminance', 'FL', '1', '0028701E', undefined)
exports.LuminanceValue = new Element(2650143, 'LuminanceValue', 'FL', '1', '0028701F', undefined)
exports.LuminanceResponseDescription = new Element(2650144, 'LuminanceResponseDescription', 'LO', '1', '00287020', undefined)
exports.WhitePointFlag = new Element(2650145, 'WhitePointFlag', 'CS', '1', '00287021', undefined)
exports.DisplayDeviceTypeCodeSequence = new Element(2650146, 'DisplayDeviceTypeCodeSequence', 'SQ', '1', '00287022', undefined)
exports.DisplaySubsystemSequence = new Element(2650147, 'DisplaySubsystemSequence', 'SQ', '1', '00287023', undefined)
exports.LuminanceResultSequence = new Element(2650148, 'LuminanceResultSequence', 'SQ', '1', '00287024', undefined)
exports.AmbientLightValueSource = new Element(2650149, 'AmbientLightValueSource', 'CS', '1', '00287025', undefined)
exports.MeasuredCharacteristics = new Element(2650150, 'MeasuredCharacteristics', 'CS', '1-n', '00287026', undefined)
exports.LuminanceUniformityResultSequence = new Element(2650151, 'LuminanceUniformityResultSequence', 'SQ', '1', '00287027', undefined)
exports.VisualEvaluationTestSequence = new Element(2650152, 'VisualEvaluationTestSequence', 'SQ', '1', '00287028', undefined)
exports.TestResult = new Element(2650153, 'TestResult', 'CS', '1', '00287029', undefined)
exports.TestResultComment = new Element(2650154, 'TestResultComment', 'LO', '1', '0028702A', undefined)
exports.TestImageValidation = new Element(2650155, 'TestImageValidation', 'CS', '1', '0028702B', undefined)
exports.TestPatternCodeSequence = new Element(2650156, 'TestPatternCodeSequence', 'SQ', '1', '0028702C', undefined)
exports.MeasurementPatternCodeSequence = new Element(2650157, 'MeasurementPatternCodeSequence', 'SQ', '1', '0028702D', undefined)
exports.VisualEvaluationMethodCodeSequence = new Element(2650158, 'VisualEvaluationMethodCodeSequence', 'SQ', '1', '0028702E', undefined)
exports.PixelDataProviderURL = new Element(2654176, 'PixelDataProviderURL', 'UT', '1', '00287FE0', undefined)
exports.DataPointRows = new Element(2658305, 'DataPointRows', 'UL', '1', '00289001', undefined)
exports.DataPointColumns = new Element(2658306, 'DataPointColumns', 'UL', '1', '00289002', undefined)
exports.SignalDomainColumns = new Element(2658307, 'SignalDomainColumns', 'CS', '1', '00289003', undefined)
exports.LargestMonochromePixelValue = new Element(2658457, 'LargestMonochromePixelValue', 'US', '1', '00289099', true)
exports.DataRepresentation = new Element(2658568, 'DataRepresentation', 'CS', '1', '00289108', undefined)
exports.PixelMeasuresSequence = new Element(2658576, 'PixelMeasuresSequence', 'SQ', '1', '00289110', undefined)
exports.FrameVOILUTSequence = new Element(2658610, 'FrameVOILUTSequence', 'SQ', '1', '00289132', undefined)
exports.PixelValueTransformationSequence = new Element(2658629, 'PixelValueTransformationSequence', 'SQ', '1', '00289145', undefined)
exports.SignalDomainRows = new Element(2658869, 'SignalDomainRows', 'CS', '1', '00289235', undefined)
exports.DisplayFilterPercentage = new Element(2659345, 'DisplayFilterPercentage', 'FL', '1', '00289411', undefined)
exports.FramePixelShiftSequence = new Element(2659349, 'FramePixelShiftSequence', 'SQ', '1', '00289415', undefined)
exports.SubtractionItemID = new Element(2659350, 'SubtractionItemID', 'US', '1', '00289416', undefined)
exports.PixelIntensityRelationshipLUTSequence = new Element(2659362, 'PixelIntensityRelationshipLUTSequence', 'SQ', '1', '00289422', undefined)
exports.FramePixelDataPropertiesSequence = new Element(2659395, 'FramePixelDataPropertiesSequence', 'SQ', '1', '00289443', undefined)
exports.GeometricalProperties = new Element(2659396, 'GeometricalProperties', 'CS', '1', '00289444', undefined)
exports.GeometricMaximumDistortion = new Element(2659397, 'GeometricMaximumDistortion', 'FL', '1', '00289445', undefined)
exports.ImageProcessingApplied = new Element(2659398, 'ImageProcessingApplied', 'CS', '1-n', '00289446', undefined)
exports.MaskSelectionMode = new Element(2659412, 'MaskSelectionMode', 'CS', '1', '00289454', undefined)
exports.LUTFunction = new Element(2659444, 'LUTFunction', 'CS', '1', '00289474', undefined)
exports.MaskVisibilityPercentage = new Element(2659448, 'MaskVisibilityPercentage', 'FL', '1', '00289478', undefined)
exports.PixelShiftSequence = new Element(2659585, 'PixelShiftSequence', 'SQ', '1', '00289501', undefined)
exports.RegionPixelShiftSequence = new Element(2659586, 'RegionPixelShiftSequence', 'SQ', '1', '00289502', undefined)
exports.VerticesOfTheRegion = new Element(2659587, 'VerticesOfTheRegion', 'SS', '2-2n', '00289503', undefined)
exports.MultiFramePresentationSequence = new Element(2659589, 'MultiFramePresentationSequence', 'SQ', '1', '00289505', undefined)
exports.PixelShiftFrameRange = new Element(2659590, 'PixelShiftFrameRange', 'US', '2-2n', '00289506', undefined)
exports.LUTFrameRange = new Element(2659591, 'LUTFrameRange', 'US', '2-2n', '00289507', undefined)
exports.ImageToEquipmentMappingMatrix = new Element(2659616, 'ImageToEquipmentMappingMatrix', 'DS', '16', '00289520', undefined)
exports.EquipmentCoordinateSystemIdentification = new Element(2659639, 'EquipmentCoordinateSystemIdentification', 'CS', '1', '00289537', undefined)
exports.StudyStatusID = new Element(3276810, 'StudyStatusID', 'CS', '1', '0032000A', true)
exports.StudyPriorityID = new Element(3276812, 'StudyPriorityID', 'CS', '1', '0032000C', true)
exports.StudyIDIssuer = new Element(3276818, 'StudyIDIssuer', 'LO', '1', '00320012', true)
exports.StudyVerifiedDate = new Element(3276850, 'StudyVerifiedDate', 'DA', '1', '00320032', true)
exports.StudyVerifiedTime = new Element(3276851, 'StudyVerifiedTime', 'TM', '1', '00320033', true)
exports.StudyReadDate = new Element(3276852, 'StudyReadDate', 'DA', '1', '00320034', true)
exports.StudyReadTime = new Element(3276853, 'StudyReadTime', 'TM', '1', '00320035', true)
exports.ScheduledStudyStartDate = new Element(3280896, 'ScheduledStudyStartDate', 'DA', '1', '00321000', true)
exports.ScheduledStudyStartTime = new Element(3280897, 'ScheduledStudyStartTime', 'TM', '1', '00321001', true)
exports.ScheduledStudyStopDate = new Element(3280912, 'ScheduledStudyStopDate', 'DA', '1', '00321010', true)
exports.ScheduledStudyStopTime = new Element(3280913, 'ScheduledStudyStopTime', 'TM', '1', '00321011', true)
exports.ScheduledStudyLocation = new Element(3280928, 'ScheduledStudyLocation', 'LO', '1', '00321020', true)
exports.ScheduledStudyLocationAETitle = new Element(3280929, 'ScheduledStudyLocationAETitle', 'AE', '1-n', '00321021', true)
exports.ReasonForStudy = new Element(3280944, 'ReasonForStudy', 'LO', '1', '00321030', true)
exports.RequestingPhysicianIdentificationSequence = new Element(3280945, 'RequestingPhysicianIdentificationSequence', 'SQ', '1', '00321031', undefined)
exports.RequestingPhysician = new Element(3280946, 'RequestingPhysician', 'PN', '1', '00321032', undefined)
exports.RequestingService = new Element(3280947, 'RequestingService', 'LO', '1', '00321033', undefined)
exports.RequestingServiceCodeSequence = new Element(3280948, 'RequestingServiceCodeSequence', 'SQ', '1', '00321034', undefined)
exports.StudyArrivalDate = new Element(3280960, 'StudyArrivalDate', 'DA', '1', '00321040', true)
exports.StudyArrivalTime = new Element(3280961, 'StudyArrivalTime', 'TM', '1', '00321041', true)
exports.StudyCompletionDate = new Element(3280976, 'StudyCompletionDate', 'DA', '1', '00321050', true)
exports.StudyCompletionTime = new Element(3280977, 'StudyCompletionTime', 'TM', '1', '00321051', true)
exports.StudyComponentStatusID = new Element(3280981, 'StudyComponentStatusID', 'CS', '1', '00321055', true)
exports.RequestedProcedureDescription = new Element(3280992, 'RequestedProcedureDescription', 'LO', '1', '00321060', undefined)
exports.RequestedProcedureCodeSequence = new Element(3280996, 'RequestedProcedureCodeSequence', 'SQ', '1', '00321064', undefined)
exports.RequestedContrastAgent = new Element(3281008, 'RequestedContrastAgent', 'LO', '1', '00321070', undefined)
exports.StudyComments = new Element(3293184, 'StudyComments', 'LT', '1', '00324000', true)
exports.ReferencedPatientAliasSequence = new Element(3670020, 'ReferencedPatientAliasSequence', 'SQ', '1', '00380004', undefined)
exports.VisitStatusID = new Element(3670024, 'VisitStatusID', 'CS', '1', '00380008', undefined)
exports.AdmissionID = new Element(3670032, 'AdmissionID', 'LO', '1', '00380010', undefined)
exports.IssuerOfAdmissionID = new Element(3670033, 'IssuerOfAdmissionID', 'LO', '1', '00380011', true)
exports.IssuerOfAdmissionIDSequence = new Element(3670036, 'IssuerOfAdmissionIDSequence', 'SQ', '1', '00380014', undefined)
exports.RouteOfAdmissions = new Element(3670038, 'RouteOfAdmissions', 'LO', '1', '00380016', undefined)
exports.ScheduledAdmissionDate = new Element(3670042, 'ScheduledAdmissionDate', 'DA', '1', '0038001A', true)
exports.ScheduledAdmissionTime = new Element(3670043, 'ScheduledAdmissionTime', 'TM', '1', '0038001B', true)
exports.ScheduledDischargeDate = new Element(3670044, 'ScheduledDischargeDate', 'DA', '1', '0038001C', true)
exports.ScheduledDischargeTime = new Element(3670045, 'ScheduledDischargeTime', 'TM', '1', '0038001D', true)
exports.ScheduledPatientInstitutionResidence = new Element(3670046, 'ScheduledPatientInstitutionResidence', 'LO', '1', '0038001E', true)
exports.AdmittingDate = new Element(3670048, 'AdmittingDate', 'DA', '1', '00380020', undefined)
exports.AdmittingTime = new Element(3670049, 'AdmittingTime', 'TM', '1', '00380021', undefined)
exports.DischargeDate = new Element(3670064, 'DischargeDate', 'DA', '1', '00380030', true)
exports.DischargeTime = new Element(3670066, 'DischargeTime', 'TM', '1', '00380032', true)
exports.DischargeDiagnosisDescription = new Element(3670080, 'DischargeDiagnosisDescription', 'LO', '1', '00380040', true)
exports.DischargeDiagnosisCodeSequence = new Element(3670084, 'DischargeDiagnosisCodeSequence', 'SQ', '1', '00380044', true)
exports.SpecialNeeds = new Element(3670096, 'SpecialNeeds', 'LO', '1', '00380050', undefined)
exports.ServiceEpisodeID = new Element(3670112, 'ServiceEpisodeID', 'LO', '1', '00380060', undefined)
exports.IssuerOfServiceEpisodeID = new Element(3670113, 'IssuerOfServiceEpisodeID', 'LO', '1', '00380061', true)
exports.ServiceEpisodeDescription = new Element(3670114, 'ServiceEpisodeDescription', 'LO', '1', '00380062', undefined)
exports.IssuerOfServiceEpisodeIDSequence = new Element(3670116, 'IssuerOfServiceEpisodeIDSequence', 'SQ', '1', '00380064', undefined)
exports.PertinentDocumentsSequence = new Element(3670272, 'PertinentDocumentsSequence', 'SQ', '1', '00380100', undefined)
exports.CurrentPatientLocation = new Element(3670784, 'CurrentPatientLocation', 'LO', '1', '00380300', undefined)
exports.PatientInstitutionResidence = new Element(3671040, 'PatientInstitutionResidence', 'LO', '1', '00380400', undefined)
exports.PatientState = new Element(3671296, 'PatientState', 'LO', '1', '00380500', undefined)
exports.PatientClinicalTrialParticipationSequence = new Element(3671298, 'PatientClinicalTrialParticipationSequence', 'SQ', '1', '00380502', undefined)
exports.VisitComments = new Element(3686400, 'VisitComments', 'LT', '1', '00384000', undefined)
exports.WaveformOriginality = new Element(3801092, 'WaveformOriginality', 'CS', '1', '003A0004', undefined)
exports.NumberOfWaveformChannels = new Element(3801093, 'NumberOfWaveformChannels', 'US', '1', '003A0005', undefined)
exports.NumberOfWaveformSamples = new Element(3801104, 'NumberOfWaveformSamples', 'UL', '1', '003A0010', undefined)
exports.SamplingFrequency = new Element(3801114, 'SamplingFrequency', 'DS', '1', '003A001A', undefined)
exports.MultiplexGroupLabel = new Element(3801120, 'MultiplexGroupLabel', 'SH', '1', '003A0020', undefined)
exports.ChannelDefinitionSequence = new Element(3801600, 'ChannelDefinitionSequence', 'SQ', '1', '003A0200', undefined)
exports.WaveformChannelNumber = new Element(3801602, 'WaveformChannelNumber', 'IS', '1', '003A0202', undefined)
exports.ChannelLabel = new Element(3801603, 'ChannelLabel', 'SH', '1', '003A0203', undefined)
exports.ChannelStatus = new Element(3801605, 'ChannelStatus', 'CS', '1-n', '003A0205', undefined)
exports.ChannelSourceSequence = new Element(3801608, 'ChannelSourceSequence', 'SQ', '1', '003A0208', undefined)
exports.ChannelSourceModifiersSequence = new Element(3801609, 'ChannelSourceModifiersSequence', 'SQ', '1', '003A0209', undefined)
exports.SourceWaveformSequence = new Element(3801610, 'SourceWaveformSequence', 'SQ', '1', '003A020A', undefined)
exports.ChannelDerivationDescription = new Element(3801612, 'ChannelDerivationDescription', 'LO', '1', '003A020C', undefined)
exports.ChannelSensitivity = new Element(3801616, 'ChannelSensitivity', 'DS', '1', '003A0210', undefined)
exports.ChannelSensitivityUnitsSequence = new Element(3801617, 'ChannelSensitivityUnitsSequence', 'SQ', '1', '003A0211', undefined)
exports.ChannelSensitivityCorrectionFactor = new Element(3801618, 'ChannelSensitivityCorrectionFactor', 'DS', '1', '003A0212', undefined)
exports.ChannelBaseline = new Element(3801619, 'ChannelBaseline', 'DS', '1', '003A0213', undefined)
exports.ChannelTimeSkew = new Element(3801620, 'ChannelTimeSkew', 'DS', '1', '003A0214', undefined)
exports.ChannelSampleSkew = new Element(3801621, 'ChannelSampleSkew', 'DS', '1', '003A0215', undefined)
exports.ChannelOffset = new Element(3801624, 'ChannelOffset', 'DS', '1', '003A0218', undefined)
exports.WaveformBitsStored = new Element(3801626, 'WaveformBitsStored', 'US', '1', '003A021A', undefined)
exports.FilterLowFrequency = new Element(3801632, 'FilterLowFrequency', 'DS', '1', '003A0220', undefined)
exports.FilterHighFrequency = new Element(3801633, 'FilterHighFrequency', 'DS', '1', '003A0221', undefined)
exports.NotchFilterFrequency = new Element(3801634, 'NotchFilterFrequency', 'DS', '1', '003A0222', undefined)
exports.NotchFilterBandwidth = new Element(3801635, 'NotchFilterBandwidth', 'DS', '1', '003A0223', undefined)
exports.WaveformDataDisplayScale = new Element(3801648, 'WaveformDataDisplayScale', 'FL', '1', '003A0230', undefined)
exports.WaveformDisplayBackgroundCIELabValue = new Element(3801649, 'WaveformDisplayBackgroundCIELabValue', 'US', '3', '003A0231', undefined)
exports.WaveformPresentationGroupSequence = new Element(3801664, 'WaveformPresentationGroupSequence', 'SQ', '1', '003A0240', undefined)
exports.PresentationGroupNumber = new Element(3801665, 'PresentationGroupNumber', 'US', '1', '003A0241', undefined)
exports.ChannelDisplaySequence = new Element(3801666, 'ChannelDisplaySequence', 'SQ', '1', '003A0242', undefined)
exports.ChannelRecommendedDisplayCIELabValue = new Element(3801668, 'ChannelRecommendedDisplayCIELabValue', 'US', '3', '003A0244', undefined)
exports.ChannelPosition = new Element(3801669, 'ChannelPosition', 'FL', '1', '003A0245', undefined)
exports.DisplayShadingFlag = new Element(3801670, 'DisplayShadingFlag', 'CS', '1', '003A0246', undefined)
exports.FractionalChannelDisplayScale = new Element(3801671, 'FractionalChannelDisplayScale', 'FL', '1', '003A0247', undefined)
exports.AbsoluteChannelDisplayScale = new Element(3801672, 'AbsoluteChannelDisplayScale', 'FL', '1', '003A0248', undefined)
exports.MultiplexedAudioChannelsDescriptionCodeSequence = new Element(3801856, 'MultiplexedAudioChannelsDescriptionCodeSequence', 'SQ', '1', '003A0300', undefined)
exports.ChannelIdentificationCode = new Element(3801857, 'ChannelIdentificationCode', 'IS', '1', '003A0301', undefined)
exports.ChannelMode = new Element(3801858, 'ChannelMode', 'CS', '1', '003A0302', undefined)
exports.ScheduledStationAETitle = new Element(4194305, 'ScheduledStationAETitle', 'AE', '1-n', '00400001', undefined)
exports.ScheduledProcedureStepStartDate = new Element(4194306, 'ScheduledProcedureStepStartDate', 'DA', '1', '00400002', undefined)
exports.ScheduledProcedureStepStartTime = new Element(4194307, 'ScheduledProcedureStepStartTime', 'TM', '1', '00400003', undefined)
exports.ScheduledProcedureStepEndDate = new Element(4194308, 'ScheduledProcedureStepEndDate', 'DA', '1', '00400004', undefined)
exports.ScheduledProcedureStepEndTime = new Element(4194309, 'ScheduledProcedureStepEndTime', 'TM', '1', '00400005', undefined)
exports.ScheduledPerformingPhysicianName = new Element(4194310, 'ScheduledPerformingPhysicianName', 'PN', '1', '00400006', undefined)
exports.ScheduledProcedureStepDescription = new Element(4194311, 'ScheduledProcedureStepDescription', 'LO', '1', '00400007', undefined)
exports.ScheduledProtocolCodeSequence = new Element(4194312, 'ScheduledProtocolCodeSequence', 'SQ', '1', '00400008', undefined)
exports.ScheduledProcedureStepID = new Element(4194313, 'ScheduledProcedureStepID', 'SH', '1', '00400009', undefined)
exports.StageCodeSequence = new Element(4194314, 'StageCodeSequence', 'SQ', '1', '0040000A', undefined)
exports.ScheduledPerformingPhysicianIdentificationSequence = new Element(4194315, 'ScheduledPerformingPhysicianIdentificationSequence', 'SQ', '1', '0040000B', undefined)
exports.ScheduledStationName = new Element(4194320, 'ScheduledStationName', 'SH', '1-n', '00400010', undefined)
exports.ScheduledProcedureStepLocation = new Element(4194321, 'ScheduledProcedureStepLocation', 'SH', '1', '00400011', undefined)
exports.PreMedication = new Element(4194322, 'PreMedication', 'LO', '1', '00400012', undefined)
exports.ScheduledProcedureStepStatus = new Element(4194336, 'ScheduledProcedureStepStatus', 'CS', '1', '00400020', undefined)
exports.OrderPlacerIdentifierSequence = new Element(4194342, 'OrderPlacerIdentifierSequence', 'SQ', '1', '00400026', undefined)
exports.OrderFillerIdentifierSequence = new Element(4194343, 'OrderFillerIdentifierSequence', 'SQ', '1', '00400027', undefined)
exports.LocalNamespaceEntityID = new Element(4194353, 'LocalNamespaceEntityID', 'UT', '1', '00400031', undefined)
exports.UniversalEntityID = new Element(4194354, 'UniversalEntityID', 'UT', '1', '00400032', undefined)
exports.UniversalEntityIDType = new Element(4194355, 'UniversalEntityIDType', 'CS', '1', '00400033', undefined)
exports.IdentifierTypeCode = new Element(4194357, 'IdentifierTypeCode', 'CS', '1', '00400035', undefined)
exports.AssigningFacilitySequence = new Element(4194358, 'AssigningFacilitySequence', 'SQ', '1', '00400036', undefined)
exports.AssigningJurisdictionCodeSequence = new Element(4194361, 'AssigningJurisdictionCodeSequence', 'SQ', '1', '00400039', undefined)
exports.AssigningAgencyOrDepartmentCodeSequence = new Element(4194362, 'AssigningAgencyOrDepartmentCodeSequence', 'SQ', '1', '0040003A', undefined)
exports.ScheduledProcedureStepSequence = new Element(4194560, 'ScheduledProcedureStepSequence', 'SQ', '1', '00400100', undefined)
exports.ReferencedNonImageCompositeSOPInstanceSequence = new Element(4194848, 'ReferencedNonImageCompositeSOPInstanceSequence', 'SQ', '1', '00400220', undefined)
exports.PerformedStationAETitle = new Element(4194881, 'PerformedStationAETitle', 'AE', '1', '00400241', undefined)
exports.PerformedStationName = new Element(4194882, 'PerformedStationName', 'SH', '1', '00400242', undefined)
exports.PerformedLocation = new Element(4194883, 'PerformedLocation', 'SH', '1', '00400243', undefined)
exports.PerformedProcedureStepStartDate = new Element(4194884, 'PerformedProcedureStepStartDate', 'DA', '1', '00400244', undefined)
exports.PerformedProcedureStepStartTime = new Element(4194885, 'PerformedProcedureStepStartTime', 'TM', '1', '00400245', undefined)
exports.PerformedProcedureStepEndDate = new Element(4194896, 'PerformedProcedureStepEndDate', 'DA', '1', '00400250', undefined)
exports.PerformedProcedureStepEndTime = new Element(4194897, 'PerformedProcedureStepEndTime', 'TM', '1', '00400251', undefined)
exports.PerformedProcedureStepStatus = new Element(4194898, 'PerformedProcedureStepStatus', 'CS', '1', '00400252', undefined)
exports.PerformedProcedureStepID = new Element(4194899, 'PerformedProcedureStepID', 'SH', '1', '00400253', undefined)
exports.PerformedProcedureStepDescription = new Element(4194900, 'PerformedProcedureStepDescription', 'LO', '1', '00400254', undefined)
exports.PerformedProcedureTypeDescription = new Element(4194901, 'PerformedProcedureTypeDescription', 'LO', '1', '00400255', undefined)
exports.PerformedProtocolCodeSequence = new Element(4194912, 'PerformedProtocolCodeSequence', 'SQ', '1', '00400260', undefined)
exports.PerformedProtocolType = new Element(4194913, 'PerformedProtocolType', 'CS', '1', '00400261', undefined)
exports.ScheduledStepAttributesSequence = new Element(4194928, 'ScheduledStepAttributesSequence', 'SQ', '1', '00400270', undefined)
exports.RequestAttributesSequence = new Element(4194933, 'RequestAttributesSequence', 'SQ', '1', '00400275', undefined)
exports.CommentsOnThePerformedProcedureStep = new Element(4194944, 'CommentsOnThePerformedProcedureStep', 'ST', '1', '00400280', undefined)
exports.PerformedProcedureStepDiscontinuationReasonCodeSequence = new Element(4194945, 'PerformedProcedureStepDiscontinuationReasonCodeSequence', 'SQ', '1', '00400281', undefined)
exports.QuantitySequence = new Element(4194963, 'QuantitySequence', 'SQ', '1', '00400293', undefined)
exports.Quantity = new Element(4194964, 'Quantity', 'DS', '1', '00400294', undefined)
exports.MeasuringUnitsSequence = new Element(4194965, 'MeasuringUnitsSequence', 'SQ', '1', '00400295', undefined)
exports.BillingItemSequence = new Element(4194966, 'BillingItemSequence', 'SQ', '1', '00400296', undefined)
exports.TotalTimeOfFluoroscopy = new Element(4195072, 'TotalTimeOfFluoroscopy', 'US', '1', '00400300', undefined)
exports.TotalNumberOfExposures = new Element(4195073, 'TotalNumberOfExposures', 'US', '1', '00400301', undefined)
exports.EntranceDose = new Element(4195074, 'EntranceDose', 'US', '1', '00400302', undefined)
exports.ExposedArea = new Element(4195075, 'ExposedArea', 'US', '1-2', '00400303', undefined)
exports.DistanceSourceToEntrance = new Element(4195078, 'DistanceSourceToEntrance', 'DS', '1', '00400306', undefined)
exports.DistanceSourceToSupport = new Element(4195079, 'DistanceSourceToSupport', 'DS', '1', '00400307', true)
exports.ExposureDoseSequence = new Element(4195086, 'ExposureDoseSequence', 'SQ', '1', '0040030E', undefined)
exports.CommentsOnRadiationDose = new Element(4195088, 'CommentsOnRadiationDose', 'ST', '1', '00400310', undefined)
exports.XRayOutput = new Element(4195090, 'XRayOutput', 'DS', '1', '00400312', undefined)
exports.HalfValueLayer = new Element(4195092, 'HalfValueLayer', 'DS', '1', '00400314', undefined)
exports.OrganDose = new Element(4195094, 'OrganDose', 'DS', '1', '00400316', undefined)
exports.OrganExposed = new Element(4195096, 'OrganExposed', 'CS', '1', '00400318', undefined)
exports.BillingProcedureStepSequence = new Element(4195104, 'BillingProcedureStepSequence', 'SQ', '1', '00400320', undefined)
exports.FilmConsumptionSequence = new Element(4195105, 'FilmConsumptionSequence', 'SQ', '1', '00400321', undefined)
exports.BillingSuppliesAndDevicesSequence = new Element(4195108, 'BillingSuppliesAndDevicesSequence', 'SQ', '1', '00400324', undefined)
exports.ReferencedProcedureStepSequence = new Element(4195120, 'ReferencedProcedureStepSequence', 'SQ', '1', '00400330', true)
exports.PerformedSeriesSequence = new Element(4195136, 'PerformedSeriesSequence', 'SQ', '1', '00400340', undefined)
exports.CommentsOnTheScheduledProcedureStep = new Element(4195328, 'CommentsOnTheScheduledProcedureStep', 'LT', '1', '00400400', undefined)
exports.ProtocolContextSequence = new Element(4195392, 'ProtocolContextSequence', 'SQ', '1', '00400440', undefined)
exports.ContentItemModifierSequence = new Element(4195393, 'ContentItemModifierSequence', 'SQ', '1', '00400441', undefined)
exports.ScheduledSpecimenSequence = new Element(4195584, 'ScheduledSpecimenSequence', 'SQ', '1', '00400500', undefined)
exports.SpecimenAccessionNumber = new Element(4195594, 'SpecimenAccessionNumber', 'LO', '1', '0040050A', true)
exports.ContainerIdentifier = new Element(4195602, 'ContainerIdentifier', 'LO', '1', '00400512', undefined)
exports.IssuerOfTheContainerIdentifierSequence = new Element(4195603, 'IssuerOfTheContainerIdentifierSequence', 'SQ', '1', '00400513', undefined)
exports.AlternateContainerIdentifierSequence = new Element(4195605, 'AlternateContainerIdentifierSequence', 'SQ', '1', '00400515', undefined)
exports.ContainerTypeCodeSequence = new Element(4195608, 'ContainerTypeCodeSequence', 'SQ', '1', '00400518', undefined)
exports.ContainerDescription = new Element(4195610, 'ContainerDescription', 'LO', '1', '0040051A', undefined)
exports.ContainerComponentSequence = new Element(4195616, 'ContainerComponentSequence', 'SQ', '1', '00400520', undefined)
exports.SpecimenSequence = new Element(4195664, 'SpecimenSequence', 'SQ', '1', '00400550', true)
exports.SpecimenIdentifier = new Element(4195665, 'SpecimenIdentifier', 'LO', '1', '00400551', undefined)
exports.SpecimenDescriptionSequenceTrial = new Element(4195666, 'SpecimenDescriptionSequenceTrial', 'SQ', '1', '00400552', true)
exports.SpecimenDescriptionTrial = new Element(4195667, 'SpecimenDescriptionTrial', 'ST', '1', '00400553', true)
exports.SpecimenUID = new Element(4195668, 'SpecimenUID', 'UI', '1', '00400554', undefined)
exports.AcquisitionContextSequence = new Element(4195669, 'AcquisitionContextSequence', 'SQ', '1', '00400555', undefined)
exports.AcquisitionContextDescription = new Element(4195670, 'AcquisitionContextDescription', 'ST', '1', '00400556', undefined)
exports.SpecimenTypeCodeSequence = new Element(4195738, 'SpecimenTypeCodeSequence', 'SQ', '1', '0040059A', undefined)
exports.SpecimenDescriptionSequence = new Element(4195680, 'SpecimenDescriptionSequence', 'SQ', '1', '00400560', undefined)
exports.IssuerOfTheSpecimenIdentifierSequence = new Element(4195682, 'IssuerOfTheSpecimenIdentifierSequence', 'SQ', '1', '00400562', undefined)
exports.SpecimenShortDescription = new Element(4195840, 'SpecimenShortDescription', 'LO', '1', '00400600', undefined)
exports.SpecimenDetailedDescription = new Element(4195842, 'SpecimenDetailedDescription', 'UT', '1', '00400602', undefined)
exports.SpecimenPreparationSequence = new Element(4195856, 'SpecimenPreparationSequence', 'SQ', '1', '00400610', undefined)
exports.SpecimenPreparationStepContentItemSequence = new Element(4195858, 'SpecimenPreparationStepContentItemSequence', 'SQ', '1', '00400612', undefined)
exports.SpecimenLocalizationContentItemSequence = new Element(4195872, 'SpecimenLocalizationContentItemSequence', 'SQ', '1', '00400620', undefined)
exports.SlideIdentifier = new Element(4196090, 'SlideIdentifier', 'LO', '1', '004006FA', true)
exports.ImageCenterPointCoordinatesSequence = new Element(4196122, 'ImageCenterPointCoordinatesSequence', 'SQ', '1', '0040071A', undefined)
exports.XOffsetInSlideCoordinateSystem = new Element(4196138, 'XOffsetInSlideCoordinateSystem', 'DS', '1', '0040072A', undefined)
exports.YOffsetInSlideCoordinateSystem = new Element(4196154, 'YOffsetInSlideCoordinateSystem', 'DS', '1', '0040073A', undefined)
exports.ZOffsetInSlideCoordinateSystem = new Element(4196170, 'ZOffsetInSlideCoordinateSystem', 'DS', '1', '0040074A', undefined)
exports.PixelSpacingSequence = new Element(4196568, 'PixelSpacingSequence', 'SQ', '1', '004008D8', true)
exports.CoordinateSystemAxisCodeSequence = new Element(4196570, 'CoordinateSystemAxisCodeSequence', 'SQ', '1', '004008DA', true)
exports.MeasurementUnitsCodeSequence = new Element(4196586, 'MeasurementUnitsCodeSequence', 'SQ', '1', '004008EA', undefined)
exports.VitalStainCodeSequenceTrial = new Element(4196856, 'VitalStainCodeSequenceTrial', 'SQ', '1', '004009F8', true)
exports.RequestedProcedureID = new Element(4198401, 'RequestedProcedureID', 'SH', '1', '00401001', undefined)
exports.ReasonForTheRequestedProcedure = new Element(4198402, 'ReasonForTheRequestedProcedure', 'LO', '1', '00401002', undefined)
exports.RequestedProcedurePriority = new Element(4198403, 'RequestedProcedurePriority', 'SH', '1', '00401003', undefined)
exports.PatientTransportArrangements = new Element(4198404, 'PatientTransportArrangements', 'LO', '1', '00401004', undefined)
exports.RequestedProcedureLocation = new Element(4198405, 'RequestedProcedureLocation', 'LO', '1', '00401005', undefined)
exports.PlacerOrderNumberProcedure = new Element(4198406, 'PlacerOrderNumberProcedure', 'SH', '1', '00401006', true)
exports.FillerOrderNumberProcedure = new Element(4198407, 'FillerOrderNumberProcedure', 'SH', '1', '00401007', true)
exports.ConfidentialityCode = new Element(4198408, 'ConfidentialityCode', 'LO', '1', '00401008', undefined)
exports.ReportingPriority = new Element(4198409, 'ReportingPriority', 'SH', '1', '00401009', undefined)
exports.ReasonForRequestedProcedureCodeSequence = new Element(4198410, 'ReasonForRequestedProcedureCodeSequence', 'SQ', '1', '0040100A', undefined)
exports.NamesOfIntendedRecipientsOfResults = new Element(4198416, 'NamesOfIntendedRecipientsOfResults', 'PN', '1-n', '00401010', undefined)
exports.IntendedRecipientsOfResultsIdentificationSequence = new Element(4198417, 'IntendedRecipientsOfResultsIdentificationSequence', 'SQ', '1', '00401011', undefined)
exports.ReasonForPerformedProcedureCodeSequence = new Element(4198418, 'ReasonForPerformedProcedureCodeSequence', 'SQ', '1', '00401012', undefined)
exports.RequestedProcedureDescriptionTrial = new Element(4198496, 'RequestedProcedureDescriptionTrial', 'LO', '1', '00401060', true)
exports.PersonIdentificationCodeSequence = new Element(4198657, 'PersonIdentificationCodeSequence', 'SQ', '1', '00401101', undefined)
exports.PersonAddress = new Element(4198658, 'PersonAddress', 'ST', '1', '00401102', undefined)
exports.PersonTelephoneNumbers = new Element(4198659, 'PersonTelephoneNumbers', 'LO', '1-n', '00401103', undefined)
exports.RequestedProcedureComments = new Element(4199424, 'RequestedProcedureComments', 'LT', '1', '00401400', undefined)
exports.ReasonForTheImagingServiceRequest = new Element(4202497, 'ReasonForTheImagingServiceRequest', 'LO', '1', '00402001', true)
exports.IssueDateOfImagingServiceRequest = new Element(4202500, 'IssueDateOfImagingServiceRequest', 'DA', '1', '00402004', undefined)
exports.IssueTimeOfImagingServiceRequest = new Element(4202501, 'IssueTimeOfImagingServiceRequest', 'TM', '1', '00402005', undefined)
exports.PlacerOrderNumberImagingServiceRequestRetired = new Element(4202502, 'PlacerOrderNumberImagingServiceRequestRetired', 'SH', '1', '00402006', true)
exports.FillerOrderNumberImagingServiceRequestRetired = new Element(4202503, 'FillerOrderNumberImagingServiceRequestRetired', 'SH', '1', '00402007', true)
exports.OrderEnteredBy = new Element(4202504, 'OrderEnteredBy', 'PN', '1', '00402008', undefined)
exports.OrderEntererLocation = new Element(4202505, 'OrderEntererLocation', 'SH', '1', '00402009', undefined)
exports.OrderCallbackPhoneNumber = new Element(4202512, 'OrderCallbackPhoneNumber', 'SH', '1', '00402010', undefined)
exports.PlacerOrderNumberImagingServiceRequest = new Element(4202518, 'PlacerOrderNumberImagingServiceRequest', 'LO', '1', '00402016', undefined)
exports.FillerOrderNumberImagingServiceRequest = new Element(4202519, 'FillerOrderNumberImagingServiceRequest', 'LO', '1', '00402017', undefined)
exports.ImagingServiceRequestComments = new Element(4203520, 'ImagingServiceRequestComments', 'LT', '1', '00402400', undefined)
exports.ConfidentialityConstraintOnPatientDataDescription = new Element(4206593, 'ConfidentialityConstraintOnPatientDataDescription', 'LO', '1', '00403001', undefined)
exports.GeneralPurposeScheduledProcedureStepStatus = new Element(4210689, 'GeneralPurposeScheduledProcedureStepStatus', 'CS', '1', '00404001', true)
exports.GeneralPurposePerformedProcedureStepStatus = new Element(4210690, 'GeneralPurposePerformedProcedureStepStatus', 'CS', '1', '00404002', true)
exports.GeneralPurposeScheduledProcedureStepPriority = new Element(4210691, 'GeneralPurposeScheduledProcedureStepPriority', 'CS', '1', '00404003', true)
exports.ScheduledProcessingApplicationsCodeSequence = new Element(4210692, 'ScheduledProcessingApplicationsCodeSequence', 'SQ', '1', '00404004', true)
exports.ScheduledProcedureStepStartDateTime = new Element(4210693, 'ScheduledProcedureStepStartDateTime', 'DT', '1', '00404005', true)
exports.MultipleCopiesFlag = new Element(4210694, 'MultipleCopiesFlag', 'CS', '1', '00404006', true)
exports.PerformedProcessingApplicationsCodeSequence = new Element(4210695, 'PerformedProcessingApplicationsCodeSequence', 'SQ', '1', '00404007', undefined)
exports.HumanPerformerCodeSequence = new Element(4210697, 'HumanPerformerCodeSequence', 'SQ', '1', '00404009', undefined)
exports.ScheduledProcedureStepModificationDateTime = new Element(4210704, 'ScheduledProcedureStepModificationDateTime', 'DT', '1', '00404010', undefined)
exports.ExpectedCompletionDateTime = new Element(4210705, 'ExpectedCompletionDateTime', 'DT', '1', '00404011', undefined)
exports.ResultingGeneralPurposePerformedProcedureStepsSequence = new Element(4210709, 'ResultingGeneralPurposePerformedProcedureStepsSequence', 'SQ', '1', '00404015', true)
exports.ReferencedGeneralPurposeScheduledProcedureStepSequence = new Element(4210710, 'ReferencedGeneralPurposeScheduledProcedureStepSequence', 'SQ', '1', '00404016', true)
exports.ScheduledWorkitemCodeSequence = new Element(4210712, 'ScheduledWorkitemCodeSequence', 'SQ', '1', '00404018', undefined)
exports.PerformedWorkitemCodeSequence = new Element(4210713, 'PerformedWorkitemCodeSequence', 'SQ', '1', '00404019', undefined)
exports.InputAvailabilityFlag = new Element(4210720, 'InputAvailabilityFlag', 'CS', '1', '00404020', undefined)
exports.InputInformationSequence = new Element(4210721, 'InputInformationSequence', 'SQ', '1', '00404021', undefined)
exports.RelevantInformationSequence = new Element(4210722, 'RelevantInformationSequence', 'SQ', '1', '00404022', true)
exports.ReferencedGeneralPurposeScheduledProcedureStepTransactionUID = new Element(4210723, 'ReferencedGeneralPurposeScheduledProcedureStepTransactionUID', 'UI', '1', '00404023', true)
exports.ScheduledStationNameCodeSequence = new Element(4210725, 'ScheduledStationNameCodeSequence', 'SQ', '1', '00404025', undefined)
exports.ScheduledStationClassCodeSequence = new Element(4210726, 'ScheduledStationClassCodeSequence', 'SQ', '1', '00404026', undefined)
exports.ScheduledStationGeographicLocationCodeSequence = new Element(4210727, 'ScheduledStationGeographicLocationCodeSequence', 'SQ', '1', '00404027', undefined)
exports.PerformedStationNameCodeSequence = new Element(4210728, 'PerformedStationNameCodeSequence', 'SQ', '1', '00404028', undefined)
exports.PerformedStationClassCodeSequence = new Element(4210729, 'PerformedStationClassCodeSequence', 'SQ', '1', '00404029', undefined)
exports.PerformedStationGeographicLocationCodeSequence = new Element(4210736, 'PerformedStationGeographicLocationCodeSequence', 'SQ', '1', '00404030', undefined)
exports.RequestedSubsequentWorkitemCodeSequence = new Element(4210737, 'RequestedSubsequentWorkitemCodeSequence', 'SQ', '1', '00404031', true)
exports.NonDICOMOutputCodeSequence = new Element(4210738, 'NonDICOMOutputCodeSequence', 'SQ', '1', '00404032', true)
exports.OutputInformationSequence = new Element(4210739, 'OutputInformationSequence', 'SQ', '1', '00404033', undefined)
exports.ScheduledHumanPerformersSequence = new Element(4210740, 'ScheduledHumanPerformersSequence', 'SQ', '1', '00404034', undefined)
exports.ActualHumanPerformersSequence = new Element(4210741, 'ActualHumanPerformersSequence', 'SQ', '1', '00404035', undefined)
exports.HumanPerformerOrganization = new Element(4210742, 'HumanPerformerOrganization', 'LO', '1', '00404036', undefined)
exports.HumanPerformerName = new Element(4210743, 'HumanPerformerName', 'PN', '1', '00404037', undefined)
exports.RawDataHandling = new Element(4210752, 'RawDataHandling', 'CS', '1', '00404040', undefined)
exports.InputReadinessState = new Element(4210753, 'InputReadinessState', 'CS', '1', '00404041', undefined)
exports.PerformedProcedureStepStartDateTime = new Element(4210768, 'PerformedProcedureStepStartDateTime', 'DT', '1', '00404050', undefined)
exports.PerformedProcedureStepEndDateTime = new Element(4210769, 'PerformedProcedureStepEndDateTime', 'DT', '1', '00404051', undefined)
exports.ProcedureStepCancellationDateTime = new Element(4210770, 'ProcedureStepCancellationDateTime', 'DT', '1', '00404052', undefined)
exports.EntranceDoseInmGy = new Element(4227842, 'EntranceDoseInmGy', 'DS', '1', '00408302', undefined)
exports.ReferencedImageRealWorldValueMappingSequence = new Element(4231316, 'ReferencedImageRealWorldValueMappingSequence', 'SQ', '1', '00409094', undefined)
exports.RealWorldValueMappingSequence = new Element(4231318, 'RealWorldValueMappingSequence', 'SQ', '1', '00409096', undefined)
exports.PixelValueMappingCodeSequence = new Element(4231320, 'PixelValueMappingCodeSequence', 'SQ', '1', '00409098', undefined)
exports.LUTLabel = new Element(4231696, 'LUTLabel', 'SH', '1', '00409210', undefined)
exports.RealWorldValueLastValueMapped = new Element(4231697, 'RealWorldValueLastValueMapped', 'US or SS', '1', '00409211', undefined)
exports.RealWorldValueLUTData = new Element(4231698, 'RealWorldValueLUTData', 'FD', '1-n', '00409212', undefined)
exports.RealWorldValueFirstValueMapped = new Element(4231702, 'RealWorldValueFirstValueMapped', 'US or SS', '1', '00409216', undefined)
exports.RealWorldValueIntercept = new Element(4231716, 'RealWorldValueIntercept', 'FD', '1', '00409224', undefined)
exports.RealWorldValueSlope = new Element(4231717, 'RealWorldValueSlope', 'FD', '1', '00409225', undefined)
exports.FindingsFlagTrial = new Element(4235271, 'FindingsFlagTrial', 'CS', '1', '0040A007', true)
exports.RelationshipType = new Element(4235280, 'RelationshipType', 'CS', '1', '0040A010', undefined)
exports.FindingsSequenceTrial = new Element(4235296, 'FindingsSequenceTrial', 'SQ', '1', '0040A020', true)
exports.FindingsGroupUIDTrial = new Element(4235297, 'FindingsGroupUIDTrial', 'UI', '1', '0040A021', true)
exports.ReferencedFindingsGroupUIDTrial = new Element(4235298, 'ReferencedFindingsGroupUIDTrial', 'UI', '1', '0040A022', true)
exports.FindingsGroupRecordingDateTrial = new Element(4235299, 'FindingsGroupRecordingDateTrial', 'DA', '1', '0040A023', true)
exports.FindingsGroupRecordingTimeTrial = new Element(4235300, 'FindingsGroupRecordingTimeTrial', 'TM', '1', '0040A024', true)
exports.FindingsSourceCategoryCodeSequenceTrial = new Element(4235302, 'FindingsSourceCategoryCodeSequenceTrial', 'SQ', '1', '0040A026', true)
exports.VerifyingOrganization = new Element(4235303, 'VerifyingOrganization', 'LO', '1', '0040A027', undefined)
exports.DocumentingOrganizationIdentifierCodeSequenceTrial = new Element(4235304, 'DocumentingOrganizationIdentifierCodeSequenceTrial', 'SQ', '1', '0040A028', true)
exports.VerificationDateTime = new Element(4235312, 'VerificationDateTime', 'DT', '1', '0040A030', undefined)
exports.ObservationDateTime = new Element(4235314, 'ObservationDateTime', 'DT', '1', '0040A032', undefined)
exports.ValueType = new Element(4235328, 'ValueType', 'CS', '1', '0040A040', undefined)
exports.ConceptNameCodeSequence = new Element(4235331, 'ConceptNameCodeSequence', 'SQ', '1', '0040A043', undefined)
exports.MeasurementPrecisionDescriptionTrial = new Element(4235335, 'MeasurementPrecisionDescriptionTrial', 'LO', '1', '0040A047', true)
exports.ContinuityOfContent = new Element(4235344, 'ContinuityOfContent', 'CS', '1', '0040A050', undefined)
exports.UrgencyOrPriorityAlertsTrial = new Element(4235351, 'UrgencyOrPriorityAlertsTrial', 'CS', '1-n', '0040A057', true)
exports.SequencingIndicatorTrial = new Element(4235360, 'SequencingIndicatorTrial', 'LO', '1', '0040A060', true)
exports.DocumentIdentifierCodeSequenceTrial = new Element(4235366, 'DocumentIdentifierCodeSequenceTrial', 'SQ', '1', '0040A066', true)
exports.DocumentAuthorTrial = new Element(4235367, 'DocumentAuthorTrial', 'PN', '1', '0040A067', true)
exports.DocumentAuthorIdentifierCodeSequenceTrial = new Element(4235368, 'DocumentAuthorIdentifierCodeSequenceTrial', 'SQ', '1', '0040A068', true)
exports.IdentifierCodeSequenceTrial = new Element(4235376, 'IdentifierCodeSequenceTrial', 'SQ', '1', '0040A070', true)
exports.VerifyingObserverSequence = new Element(4235379, 'VerifyingObserverSequence', 'SQ', '1', '0040A073', undefined)
exports.ObjectBinaryIdentifierTrial = new Element(4235380, 'ObjectBinaryIdentifierTrial', 'OB', '1', '0040A074', true)
exports.VerifyingObserverName = new Element(4235381, 'VerifyingObserverName', 'PN', '1', '0040A075', undefined)
exports.DocumentingObserverIdentifierCodeSequenceTrial = new Element(4235382, 'DocumentingObserverIdentifierCodeSequenceTrial', 'SQ', '1', '0040A076', true)
exports.AuthorObserverSequence = new Element(4235384, 'AuthorObserverSequence', 'SQ', '1', '0040A078', undefined)
exports.ParticipantSequence = new Element(4235386, 'ParticipantSequence', 'SQ', '1', '0040A07A', undefined)
exports.CustodialOrganizationSequence = new Element(4235388, 'CustodialOrganizationSequence', 'SQ', '1', '0040A07C', undefined)
exports.ParticipationType = new Element(4235392, 'ParticipationType', 'CS', '1', '0040A080', undefined)
exports.ParticipationDateTime = new Element(4235394, 'ParticipationDateTime', 'DT', '1', '0040A082', undefined)
exports.ObserverType = new Element(4235396, 'ObserverType', 'CS', '1', '0040A084', undefined)
exports.ProcedureIdentifierCodeSequenceTrial = new Element(4235397, 'ProcedureIdentifierCodeSequenceTrial', 'SQ', '1', '0040A085', true)
exports.VerifyingObserverIdentificationCodeSequence = new Element(4235400, 'VerifyingObserverIdentificationCodeSequence', 'SQ', '1', '0040A088', undefined)
exports.ObjectDirectoryBinaryIdentifierTrial = new Element(4235401, 'ObjectDirectoryBinaryIdentifierTrial', 'OB', '1', '0040A089', true)
exports.EquivalentCDADocumentSequence = new Element(4235408, 'EquivalentCDADocumentSequence', 'SQ', '1', '0040A090', true)
exports.ReferencedWaveformChannels = new Element(4235440, 'ReferencedWaveformChannels', 'US', '2-2n', '0040A0B0', undefined)
exports.DateOfDocumentOrVerbalTransactionTrial = new Element(4235536, 'DateOfDocumentOrVerbalTransactionTrial', 'DA', '1', '0040A110', true)
exports.TimeOfDocumentCreationOrVerbalTransactionTrial = new Element(4235538, 'TimeOfDocumentCreationOrVerbalTransactionTrial', 'TM', '1', '0040A112', true)
exports.DateTime = new Element(4235552, 'DateTime', 'DT', '1', '0040A120', undefined)
exports.Date = new Element(4235553, 'Date', 'DA', '1', '0040A121', undefined)
exports.Time = new Element(4235554, 'Time', 'TM', '1', '0040A122', undefined)
exports.PersonName = new Element(4235555, 'PersonName', 'PN', '1', '0040A123', undefined)
exports.UID = new Element(4235556, 'UID', 'UI', '1', '0040A124', undefined)
exports.ReportStatusIDTrial = new Element(4235557, 'ReportStatusIDTrial', 'CS', '2', '0040A125', true)
exports.TemporalRangeType = new Element(4235568, 'TemporalRangeType', 'CS', '1', '0040A130', undefined)
exports.ReferencedSamplePositions = new Element(4235570, 'ReferencedSamplePositions', 'UL', '1-n', '0040A132', undefined)
exports.ReferencedFrameNumbers = new Element(4235574, 'ReferencedFrameNumbers', 'US', '1-n', '0040A136', undefined)
exports.ReferencedTimeOffsets = new Element(4235576, 'ReferencedTimeOffsets', 'DS', '1-n', '0040A138', undefined)
exports.ReferencedDateTime = new Element(4235578, 'ReferencedDateTime', 'DT', '1-n', '0040A13A', undefined)
exports.TextValue = new Element(4235616, 'TextValue', 'UT', '1', '0040A160', undefined)
exports.FloatingPointValue = new Element(4235617, 'FloatingPointValue', 'FD', '1-n', '0040A161', undefined)
exports.RationalNumeratorValue = new Element(4235618, 'RationalNumeratorValue', 'SL', '1-n', '0040A162', undefined)
exports.RationalDenominatorValue = new Element(4235619, 'RationalDenominatorValue', 'UL', '1-n', '0040A163', undefined)
exports.ObservationCategoryCodeSequenceTrial = new Element(4235623, 'ObservationCategoryCodeSequenceTrial', 'SQ', '1', '0040A167', true)
exports.ConceptCodeSequence = new Element(4235624, 'ConceptCodeSequence', 'SQ', '1', '0040A168', undefined)
exports.BibliographicCitationTrial = new Element(4235626, 'BibliographicCitationTrial', 'ST', '1', '0040A16A', true)
exports.PurposeOfReferenceCodeSequence = new Element(4235632, 'PurposeOfReferenceCodeSequence', 'SQ', '1', '0040A170', undefined)
exports.ObservationUID = new Element(4235633, 'ObservationUID', 'UI', '1', '0040A171', undefined)
exports.ReferencedObservationUIDTrial = new Element(4235634, 'ReferencedObservationUIDTrial', 'UI', '1', '0040A172', true)
exports.ReferencedObservationClassTrial = new Element(4235635, 'ReferencedObservationClassTrial', 'CS', '1', '0040A173', true)
exports.ReferencedObjectObservationClassTrial = new Element(4235636, 'ReferencedObjectObservationClassTrial', 'CS', '1', '0040A174', true)
exports.AnnotationGroupNumber = new Element(4235648, 'AnnotationGroupNumber', 'US', '1', '0040A180', undefined)
exports.ObservationDateTrial = new Element(4235666, 'ObservationDateTrial', 'DA', '1', '0040A192', true)
exports.ObservationTimeTrial = new Element(4235667, 'ObservationTimeTrial', 'TM', '1', '0040A193', true)
exports.MeasurementAutomationTrial = new Element(4235668, 'MeasurementAutomationTrial', 'CS', '1', '0040A194', true)
exports.ModifierCodeSequence = new Element(4235669, 'ModifierCodeSequence', 'SQ', '1', '0040A195', undefined)
exports.IdentificationDescriptionTrial = new Element(4235812, 'IdentificationDescriptionTrial', 'ST', '1', '0040A224', true)
exports.CoordinatesSetGeometricTypeTrial = new Element(4235920, 'CoordinatesSetGeometricTypeTrial', 'CS', '1', '0040A290', true)
exports.AlgorithmCodeSequenceTrial = new Element(4235926, 'AlgorithmCodeSequenceTrial', 'SQ', '1', '0040A296', true)
exports.AlgorithmDescriptionTrial = new Element(4235927, 'AlgorithmDescriptionTrial', 'ST', '1', '0040A297', true)
exports.PixelCoordinatesSetTrial = new Element(4235930, 'PixelCoordinatesSetTrial', 'SL', '2-2n', '0040A29A', true)
exports.MeasuredValueSequence = new Element(4236032, 'MeasuredValueSequence', 'SQ', '1', '0040A300', undefined)
exports.NumericValueQualifierCodeSequence = new Element(4236033, 'NumericValueQualifierCodeSequence', 'SQ', '1', '0040A301', undefined)
exports.CurrentObserverTrial = new Element(4236039, 'CurrentObserverTrial', 'PN', '1', '0040A307', true)
exports.NumericValue = new Element(4236042, 'NumericValue', 'DS', '1-n', '0040A30A', undefined)
exports.ReferencedAccessionSequenceTrial = new Element(4236051, 'ReferencedAccessionSequenceTrial', 'SQ', '1', '0040A313', true)
exports.ReportStatusCommentTrial = new Element(4236090, 'ReportStatusCommentTrial', 'ST', '1', '0040A33A', true)
exports.ProcedureContextSequenceTrial = new Element(4236096, 'ProcedureContextSequenceTrial', 'SQ', '1', '0040A340', true)
exports.VerbalSourceTrial = new Element(4236114, 'VerbalSourceTrial', 'PN', '1', '0040A352', true)
exports.AddressTrial = new Element(4236115, 'AddressTrial', 'ST', '1', '0040A353', true)
exports.TelephoneNumberTrial = new Element(4236116, 'TelephoneNumberTrial', 'LO', '1', '0040A354', true)
exports.VerbalSourceIdentifierCodeSequenceTrial = new Element(4236120, 'VerbalSourceIdentifierCodeSequenceTrial', 'SQ', '1', '0040A358', true)
exports.PredecessorDocumentsSequence = new Element(4236128, 'PredecessorDocumentsSequence', 'SQ', '1', '0040A360', undefined)
exports.ReferencedRequestSequence = new Element(4236144, 'ReferencedRequestSequence', 'SQ', '1', '0040A370', undefined)
exports.PerformedProcedureCodeSequence = new Element(4236146, 'PerformedProcedureCodeSequence', 'SQ', '1', '0040A372', undefined)
exports.CurrentRequestedProcedureEvidenceSequence = new Element(4236149, 'CurrentRequestedProcedureEvidenceSequence', 'SQ', '1', '0040A375', undefined)
exports.ReportDetailSequenceTrial = new Element(4236160, 'ReportDetailSequenceTrial', 'SQ', '1', '0040A380', true)
exports.PertinentOtherEvidenceSequence = new Element(4236165, 'PertinentOtherEvidenceSequence', 'SQ', '1', '0040A385', undefined)
exports.HL7StructuredDocumentReferenceSequence = new Element(4236176, 'HL7StructuredDocumentReferenceSequence', 'SQ', '1', '0040A390', undefined)
exports.ObservationSubjectUIDTrial = new Element(4236290, 'ObservationSubjectUIDTrial', 'UI', '1', '0040A402', true)
exports.ObservationSubjectClassTrial = new Element(4236291, 'ObservationSubjectClassTrial', 'CS', '1', '0040A403', true)
exports.ObservationSubjectTypeCodeSequenceTrial = new Element(4236292, 'ObservationSubjectTypeCodeSequenceTrial', 'SQ', '1', '0040A404', true)
exports.CompletionFlag = new Element(4236433, 'CompletionFlag', 'CS', '1', '0040A491', undefined)
exports.CompletionFlagDescription = new Element(4236434, 'CompletionFlagDescription', 'LO', '1', '0040A492', undefined)
exports.VerificationFlag = new Element(4236435, 'VerificationFlag', 'CS', '1', '0040A493', undefined)
exports.ArchiveRequested = new Element(4236436, 'ArchiveRequested', 'CS', '1', '0040A494', undefined)
exports.PreliminaryFlag = new Element(4236438, 'PreliminaryFlag', 'CS', '1', '0040A496', undefined)
exports.ContentTemplateSequence = new Element(4236548, 'ContentTemplateSequence', 'SQ', '1', '0040A504', undefined)
exports.IdenticalDocumentsSequence = new Element(4236581, 'IdenticalDocumentsSequence', 'SQ', '1', '0040A525', undefined)
exports.ObservationSubjectContextFlagTrial = new Element(4236800, 'ObservationSubjectContextFlagTrial', 'CS', '1', '0040A600', true)
exports.ObserverContextFlagTrial = new Element(4236801, 'ObserverContextFlagTrial', 'CS', '1', '0040A601', true)
exports.ProcedureContextFlagTrial = new Element(4236803, 'ProcedureContextFlagTrial', 'CS', '1', '0040A603', true)
exports.ContentSequence = new Element(4237104, 'ContentSequence', 'SQ', '1', '0040A730', undefined)
exports.RelationshipSequenceTrial = new Element(4237105, 'RelationshipSequenceTrial', 'SQ', '1', '0040A731', true)
exports.RelationshipTypeCodeSequenceTrial = new Element(4237106, 'RelationshipTypeCodeSequenceTrial', 'SQ', '1', '0040A732', true)
exports.LanguageCodeSequenceTrial = new Element(4237124, 'LanguageCodeSequenceTrial', 'SQ', '1', '0040A744', true)
exports.UniformResourceLocatorTrial = new Element(4237714, 'UniformResourceLocatorTrial', 'ST', '1', '0040A992', true)
exports.WaveformAnnotationSequence = new Element(4239392, 'WaveformAnnotationSequence', 'SQ', '1', '0040B020', undefined)
exports.TemplateIdentifier = new Element(4250368, 'TemplateIdentifier', 'CS', '1', '0040DB00', undefined)
exports.TemplateVersion = new Element(4250374, 'TemplateVersion', 'DT', '1', '0040DB06', true)
exports.TemplateLocalVersion = new Element(4250375, 'TemplateLocalVersion', 'DT', '1', '0040DB07', true)
exports.TemplateExtensionFlag = new Element(4250379, 'TemplateExtensionFlag', 'CS', '1', '0040DB0B', true)
exports.TemplateExtensionOrganizationUID = new Element(4250380, 'TemplateExtensionOrganizationUID', 'UI', '1', '0040DB0C', true)
exports.TemplateExtensionCreatorUID = new Element(4250381, 'TemplateExtensionCreatorUID', 'UI', '1', '0040DB0D', true)
exports.ReferencedContentItemIdentifier = new Element(4250483, 'ReferencedContentItemIdentifier', 'UL', '1-n', '0040DB73', undefined)
exports.HL7InstanceIdentifier = new Element(4251649, 'HL7InstanceIdentifier', 'ST', '1', '0040E001', undefined)
exports.HL7DocumentEffectiveTime = new Element(4251652, 'HL7DocumentEffectiveTime', 'DT', '1', '0040E004', undefined)
exports.HL7DocumentTypeCodeSequence = new Element(4251654, 'HL7DocumentTypeCodeSequence', 'SQ', '1', '0040E006', undefined)
exports.DocumentClassCodeSequence = new Element(4251656, 'DocumentClassCodeSequence', 'SQ', '1', '0040E008', undefined)
exports.RetrieveURI = new Element(4251664, 'RetrieveURI', 'UT', '1', '0040E010', undefined)
exports.RetrieveLocationUID = new Element(4251665, 'RetrieveLocationUID', 'UI', '1', '0040E011', undefined)
exports.TypeOfInstances = new Element(4251680, 'TypeOfInstances', 'CS', '1', '0040E020', undefined)
exports.DICOMRetrievalSequence = new Element(4251681, 'DICOMRetrievalSequence', 'SQ', '1', '0040E021', undefined)
exports.DICOMMediaRetrievalSequence = new Element(4251682, 'DICOMMediaRetrievalSequence', 'SQ', '1', '0040E022', undefined)
exports.WADORetrievalSequence = new Element(4251683, 'WADORetrievalSequence', 'SQ', '1', '0040E023', undefined)
exports.XDSRetrievalSequence = new Element(4251684, 'XDSRetrievalSequence', 'SQ', '1', '0040E024', undefined)
exports.RepositoryUniqueID = new Element(4251696, 'RepositoryUniqueID', 'UI', '1', '0040E030', undefined)
exports.HomeCommunityID = new Element(4251697, 'HomeCommunityID', 'UI', '1', '0040E031', undefined)
exports.DocumentTitle = new Element(4325392, 'DocumentTitle', 'ST', '1', '00420010', undefined)
exports.EncapsulatedDocument = new Element(4325393, 'EncapsulatedDocument', 'OB', '1', '00420011', undefined)
exports.MIMETypeOfEncapsulatedDocument = new Element(4325394, 'MIMETypeOfEncapsulatedDocument', 'LO', '1', '00420012', undefined)
exports.SourceInstanceSequence = new Element(4325395, 'SourceInstanceSequence', 'SQ', '1', '00420013', undefined)
exports.ListOfMIMETypes = new Element(4325396, 'ListOfMIMETypes', 'LO', '1-n', '00420014', undefined)
exports.ProductPackageIdentifier = new Element(4456449, 'ProductPackageIdentifier', 'ST', '1', '00440001', undefined)
exports.SubstanceAdministrationApproval = new Element(4456450, 'SubstanceAdministrationApproval', 'CS', '1', '00440002', undefined)
exports.ApprovalStatusFurtherDescription = new Element(4456451, 'ApprovalStatusFurtherDescription', 'LT', '1', '00440003', undefined)
exports.ApprovalStatusDateTime = new Element(4456452, 'ApprovalStatusDateTime', 'DT', '1', '00440004', undefined)
exports.ProductTypeCodeSequence = new Element(4456455, 'ProductTypeCodeSequence', 'SQ', '1', '00440007', undefined)
exports.ProductName = new Element(4456456, 'ProductName', 'LO', '1-n', '00440008', undefined)
exports.ProductDescription = new Element(4456457, 'ProductDescription', 'LT', '1', '00440009', undefined)
exports.ProductLotIdentifier = new Element(4456458, 'ProductLotIdentifier', 'LO', '1', '0044000A', undefined)
exports.ProductExpirationDateTime = new Element(4456459, 'ProductExpirationDateTime', 'DT', '1', '0044000B', undefined)
exports.SubstanceAdministrationDateTime = new Element(4456464, 'SubstanceAdministrationDateTime', 'DT', '1', '00440010', undefined)
exports.SubstanceAdministrationNotes = new Element(4456465, 'SubstanceAdministrationNotes', 'LO', '1', '00440011', undefined)
exports.SubstanceAdministrationDeviceID = new Element(4456466, 'SubstanceAdministrationDeviceID', 'LO', '1', '00440012', undefined)
exports.ProductParameterSequence = new Element(4456467, 'ProductParameterSequence', 'SQ', '1', '00440013', undefined)
exports.SubstanceAdministrationParameterSequence = new Element(4456473, 'SubstanceAdministrationParameterSequence', 'SQ', '1', '00440019', undefined)
exports.LensDescription = new Element(4587538, 'LensDescription', 'LO', '1', '00460012', undefined)
exports.RightLensSequence = new Element(4587540, 'RightLensSequence', 'SQ', '1', '00460014', undefined)
exports.LeftLensSequence = new Element(4587541, 'LeftLensSequence', 'SQ', '1', '00460015', undefined)
exports.UnspecifiedLateralityLensSequence = new Element(4587542, 'UnspecifiedLateralityLensSequence', 'SQ', '1', '00460016', undefined)
exports.CylinderSequence = new Element(4587544, 'CylinderSequence', 'SQ', '1', '00460018', undefined)
exports.PrismSequence = new Element(4587560, 'PrismSequence', 'SQ', '1', '00460028', undefined)
exports.HorizontalPrismPower = new Element(4587568, 'HorizontalPrismPower', 'FD', '1', '00460030', undefined)
exports.HorizontalPrismBase = new Element(4587570, 'HorizontalPrismBase', 'CS', '1', '00460032', undefined)
exports.VerticalPrismPower = new Element(4587572, 'VerticalPrismPower', 'FD', '1', '00460034', undefined)
exports.VerticalPrismBase = new Element(4587574, 'VerticalPrismBase', 'CS', '1', '00460036', undefined)
exports.LensSegmentType = new Element(4587576, 'LensSegmentType', 'CS', '1', '00460038', undefined)
exports.OpticalTransmittance = new Element(4587584, 'OpticalTransmittance', 'FD', '1', '00460040', undefined)
exports.ChannelWidth = new Element(4587586, 'ChannelWidth', 'FD', '1', '00460042', undefined)
exports.PupilSize = new Element(4587588, 'PupilSize', 'FD', '1', '00460044', undefined)
exports.CornealSize = new Element(4587590, 'CornealSize', 'FD', '1', '00460046', undefined)
exports.AutorefractionRightEyeSequence = new Element(4587600, 'AutorefractionRightEyeSequence', 'SQ', '1', '00460050', undefined)
exports.AutorefractionLeftEyeSequence = new Element(4587602, 'AutorefractionLeftEyeSequence', 'SQ', '1', '00460052', undefined)
exports.DistancePupillaryDistance = new Element(4587616, 'DistancePupillaryDistance', 'FD', '1', '00460060', undefined)
exports.NearPupillaryDistance = new Element(4587618, 'NearPupillaryDistance', 'FD', '1', '00460062', undefined)
exports.IntermediatePupillaryDistance = new Element(4587619, 'IntermediatePupillaryDistance', 'FD', '1', '00460063', undefined)
exports.OtherPupillaryDistance = new Element(4587620, 'OtherPupillaryDistance', 'FD', '1', '00460064', undefined)
exports.KeratometryRightEyeSequence = new Element(4587632, 'KeratometryRightEyeSequence', 'SQ', '1', '00460070', undefined)
exports.KeratometryLeftEyeSequence = new Element(4587633, 'KeratometryLeftEyeSequence', 'SQ', '1', '00460071', undefined)
exports.SteepKeratometricAxisSequence = new Element(4587636, 'SteepKeratometricAxisSequence', 'SQ', '1', '00460074', undefined)
exports.RadiusOfCurvature = new Element(4587637, 'RadiusOfCurvature', 'FD', '1', '00460075', undefined)
exports.KeratometricPower = new Element(4587638, 'KeratometricPower', 'FD', '1', '00460076', undefined)
exports.KeratometricAxis = new Element(4587639, 'KeratometricAxis', 'FD', '1', '00460077', undefined)
exports.FlatKeratometricAxisSequence = new Element(4587648, 'FlatKeratometricAxisSequence', 'SQ', '1', '00460080', undefined)
exports.BackgroundColor = new Element(4587666, 'BackgroundColor', 'CS', '1', '00460092', undefined)
exports.Optotype = new Element(4587668, 'Optotype', 'CS', '1', '00460094', undefined)
exports.OptotypePresentation = new Element(4587669, 'OptotypePresentation', 'CS', '1', '00460095', undefined)
exports.SubjectiveRefractionRightEyeSequence = new Element(4587671, 'SubjectiveRefractionRightEyeSequence', 'SQ', '1', '00460097', undefined)
exports.SubjectiveRefractionLeftEyeSequence = new Element(4587672, 'SubjectiveRefractionLeftEyeSequence', 'SQ', '1', '00460098', undefined)
exports.AddNearSequence = new Element(4587776, 'AddNearSequence', 'SQ', '1', '00460100', undefined)
exports.AddIntermediateSequence = new Element(4587777, 'AddIntermediateSequence', 'SQ', '1', '00460101', undefined)
exports.AddOtherSequence = new Element(4587778, 'AddOtherSequence', 'SQ', '1', '00460102', undefined)
exports.AddPower = new Element(4587780, 'AddPower', 'FD', '1', '00460104', undefined)
exports.ViewingDistance = new Element(4587782, 'ViewingDistance', 'FD', '1', '00460106', undefined)
exports.VisualAcuityTypeCodeSequence = new Element(4587809, 'VisualAcuityTypeCodeSequence', 'SQ', '1', '00460121', undefined)
exports.VisualAcuityRightEyeSequence = new Element(4587810, 'VisualAcuityRightEyeSequence', 'SQ', '1', '00460122', undefined)
exports.VisualAcuityLeftEyeSequence = new Element(4587811, 'VisualAcuityLeftEyeSequence', 'SQ', '1', '00460123', undefined)
exports.VisualAcuityBothEyesOpenSequence = new Element(4587812, 'VisualAcuityBothEyesOpenSequence', 'SQ', '1', '00460124', undefined)
exports.ViewingDistanceType = new Element(4587813, 'ViewingDistanceType', 'CS', '1', '00460125', undefined)
exports.VisualAcuityModifiers = new Element(4587829, 'VisualAcuityModifiers', 'SS', '2', '00460135', undefined)
exports.DecimalVisualAcuity = new Element(4587831, 'DecimalVisualAcuity', 'FD', '1', '00460137', undefined)
exports.OptotypeDetailedDefinition = new Element(4587833, 'OptotypeDetailedDefinition', 'LO', '1', '00460139', undefined)
exports.ReferencedRefractiveMeasurementsSequence = new Element(4587845, 'ReferencedRefractiveMeasurementsSequence', 'SQ', '1', '00460145', undefined)
exports.SpherePower = new Element(4587846, 'SpherePower', 'FD', '1', '00460146', undefined)
exports.CylinderPower = new Element(4587847, 'CylinderPower', 'FD', '1', '00460147', undefined)
exports.CornealTopographySurface = new Element(4588033, 'CornealTopographySurface', 'CS', '1', '00460201', undefined)
exports.CornealVertexLocation = new Element(4588034, 'CornealVertexLocation', 'FL', '2', '00460202', undefined)
exports.PupilCentroidXCoordinate = new Element(4588035, 'PupilCentroidXCoordinate', 'FL', '1', '00460203', undefined)
exports.PupilCentroidYCoordinate = new Element(4588036, 'PupilCentroidYCoordinate', 'FL', '1', '00460204', undefined)
exports.EquivalentPupilRadius = new Element(4588037, 'EquivalentPupilRadius', 'FL', '1', '00460205', undefined)
exports.CornealTopographyMapTypeCodeSequence = new Element(4588039, 'CornealTopographyMapTypeCodeSequence', 'SQ', '1', '00460207', undefined)
exports.VerticesOfTheOutlineOfPupil = new Element(4588040, 'VerticesOfTheOutlineOfPupil', 'IS', '2-2n', '00460208', undefined)
exports.CornealTopographyMappingNormalsSequence = new Element(4588048, 'CornealTopographyMappingNormalsSequence', 'SQ', '1', '00460210', undefined)
exports.MaximumCornealCurvatureSequence = new Element(4588049, 'MaximumCornealCurvatureSequence', 'SQ', '1', '00460211', undefined)
exports.MaximumCornealCurvature = new Element(4588050, 'MaximumCornealCurvature', 'FL', '1', '00460212', undefined)
exports.MaximumCornealCurvatureLocation = new Element(4588051, 'MaximumCornealCurvatureLocation', 'FL', '2', '00460213', undefined)
exports.MinimumKeratometricSequence = new Element(4588053, 'MinimumKeratometricSequence', 'SQ', '1', '00460215', undefined)
exports.SimulatedKeratometricCylinderSequence = new Element(4588056, 'SimulatedKeratometricCylinderSequence', 'SQ', '1', '00460218', undefined)
exports.AverageCornealPower = new Element(4588064, 'AverageCornealPower', 'FL', '1', '00460220', undefined)
exports.CornealISValue = new Element(4588068, 'CornealISValue', 'FL', '1', '00460224', undefined)
exports.AnalyzedArea = new Element(4588071, 'AnalyzedArea', 'FL', '1', '00460227', undefined)
exports.SurfaceRegularityIndex = new Element(4588080, 'SurfaceRegularityIndex', 'FL', '1', '00460230', undefined)
exports.SurfaceAsymmetryIndex = new Element(4588082, 'SurfaceAsymmetryIndex', 'FL', '1', '00460232', undefined)
exports.CornealEccentricityIndex = new Element(4588084, 'CornealEccentricityIndex', 'FL', '1', '00460234', undefined)
exports.KeratoconusPredictionIndex = new Element(4588086, 'KeratoconusPredictionIndex', 'FL', '1', '00460236', undefined)
exports.DecimalPotentialVisualAcuity = new Element(4588088, 'DecimalPotentialVisualAcuity', 'FL', '1', '00460238', undefined)
exports.CornealTopographyMapQualityEvaluation = new Element(4588098, 'CornealTopographyMapQualityEvaluation', 'CS', '1', '00460242', undefined)
exports.SourceImageCornealProcessedDataSequence = new Element(4588100, 'SourceImageCornealProcessedDataSequence', 'SQ', '1', '00460244', undefined)
exports.CornealPointLocation = new Element(4588103, 'CornealPointLocation', 'FL', '3', '00460247', undefined)
exports.CornealPointEstimated = new Element(4588104, 'CornealPointEstimated', 'CS', '1', '00460248', undefined)
exports.AxialPower = new Element(4588105, 'AxialPower', 'FL', '1', '00460249', undefined)
exports.TangentialPower = new Element(4588112, 'TangentialPower', 'FL', '1', '00460250', undefined)
exports.RefractivePower = new Element(4588113, 'RefractivePower', 'FL', '1', '00460251', undefined)
exports.RelativeElevation = new Element(4588114, 'RelativeElevation', 'FL', '1', '00460252', undefined)
exports.CornealWavefront = new Element(4588115, 'CornealWavefront', 'FL', '1', '00460253', undefined)
exports.ImagedVolumeWidth = new Element(4718593, 'ImagedVolumeWidth', 'FL', '1', '00480001', undefined)
exports.ImagedVolumeHeight = new Element(4718594, 'ImagedVolumeHeight', 'FL', '1', '00480002', undefined)
exports.ImagedVolumeDepth = new Element(4718595, 'ImagedVolumeDepth', 'FL', '1', '00480003', undefined)
exports.TotalPixelMatrixColumns = new Element(4718598, 'TotalPixelMatrixColumns', 'UL', '1', '00480006', undefined)
exports.TotalPixelMatrixRows = new Element(4718599, 'TotalPixelMatrixRows', 'UL', '1', '00480007', undefined)
exports.TotalPixelMatrixOriginSequence = new Element(4718600, 'TotalPixelMatrixOriginSequence', 'SQ', '1', '00480008', undefined)
exports.SpecimenLabelInImage = new Element(4718608, 'SpecimenLabelInImage', 'CS', '1', '00480010', undefined)
exports.FocusMethod = new Element(4718609, 'FocusMethod', 'CS', '1', '00480011', undefined)
exports.ExtendedDepthOfField = new Element(4718610, 'ExtendedDepthOfField', 'CS', '1', '00480012', undefined)
exports.NumberOfFocalPlanes = new Element(4718611, 'NumberOfFocalPlanes', 'US', '1', '00480013', undefined)
exports.DistanceBetweenFocalPlanes = new Element(4718612, 'DistanceBetweenFocalPlanes', 'FL', '1', '00480014', undefined)
exports.RecommendedAbsentPixelCIELabValue = new Element(4718613, 'RecommendedAbsentPixelCIELabValue', 'US', '3', '00480015', undefined)
exports.IlluminatorTypeCodeSequence = new Element(4718848, 'IlluminatorTypeCodeSequence', 'SQ', '1', '00480100', undefined)
exports.ImageOrientationSlide = new Element(4718850, 'ImageOrientationSlide', 'DS', '6', '00480102', undefined)
exports.OpticalPathSequence = new Element(4718853, 'OpticalPathSequence', 'SQ', '1', '00480105', undefined)
exports.OpticalPathIdentifier = new Element(4718854, 'OpticalPathIdentifier', 'SH', '1', '00480106', undefined)
exports.OpticalPathDescription = new Element(4718855, 'OpticalPathDescription', 'ST', '1', '00480107', undefined)
exports.IlluminationColorCodeSequence = new Element(4718856, 'IlluminationColorCodeSequence', 'SQ', '1', '00480108', undefined)
exports.SpecimenReferenceSequence = new Element(4718864, 'SpecimenReferenceSequence', 'SQ', '1', '00480110', undefined)
exports.CondenserLensPower = new Element(4718865, 'CondenserLensPower', 'DS', '1', '00480111', undefined)
exports.ObjectiveLensPower = new Element(4718866, 'ObjectiveLensPower', 'DS', '1', '00480112', undefined)
exports.ObjectiveLensNumericalAperture = new Element(4718867, 'ObjectiveLensNumericalAperture', 'DS', '1', '00480113', undefined)
exports.PaletteColorLookupTableSequence = new Element(4718880, 'PaletteColorLookupTableSequence', 'SQ', '1', '00480120', undefined)
exports.ReferencedImageNavigationSequence = new Element(4719104, 'ReferencedImageNavigationSequence', 'SQ', '1', '00480200', undefined)
exports.TopLeftHandCornerOfLocalizerArea = new Element(4719105, 'TopLeftHandCornerOfLocalizerArea', 'US', '2', '00480201', undefined)
exports.BottomRightHandCornerOfLocalizerArea = new Element(4719106, 'BottomRightHandCornerOfLocalizerArea', 'US', '2', '00480202', undefined)
exports.OpticalPathIdentificationSequence = new Element(4719111, 'OpticalPathIdentificationSequence', 'SQ', '1', '00480207', undefined)
exports.PlanePositionSlideSequence = new Element(4719130, 'PlanePositionSlideSequence', 'SQ', '1', '0048021A', undefined)
exports.ColumnPositionInTotalImagePixelMatrix = new Element(4719134, 'ColumnPositionInTotalImagePixelMatrix', 'SL', '1', '0048021E', undefined)
exports.RowPositionInTotalImagePixelMatrix = new Element(4719135, 'RowPositionInTotalImagePixelMatrix', 'SL', '1', '0048021F', undefined)
exports.PixelOriginInterpretation = new Element(4719361, 'PixelOriginInterpretation', 'CS', '1', '00480301', undefined)
exports.CalibrationImage = new Element(5242884, 'CalibrationImage', 'CS', '1', '00500004', undefined)
exports.DeviceSequence = new Element(5242896, 'DeviceSequence', 'SQ', '1', '00500010', undefined)
exports.ContainerComponentTypeCodeSequence = new Element(5242898, 'ContainerComponentTypeCodeSequence', 'SQ', '1', '00500012', undefined)
exports.ContainerComponentThickness = new Element(5242899, 'ContainerComponentThickness', 'FD', '1', '00500013', undefined)
exports.DeviceLength = new Element(5242900, 'DeviceLength', 'DS', '1', '00500014', undefined)
exports.ContainerComponentWidth = new Element(5242901, 'ContainerComponentWidth', 'FD', '1', '00500015', undefined)
exports.DeviceDiameter = new Element(5242902, 'DeviceDiameter', 'DS', '1', '00500016', undefined)
exports.DeviceDiameterUnits = new Element(5242903, 'DeviceDiameterUnits', 'CS', '1', '00500017', undefined)
exports.DeviceVolume = new Element(5242904, 'DeviceVolume', 'DS', '1', '00500018', undefined)
exports.InterMarkerDistance = new Element(5242905, 'InterMarkerDistance', 'DS', '1', '00500019', undefined)
exports.ContainerComponentMaterial = new Element(5242906, 'ContainerComponentMaterial', 'CS', '1', '0050001A', undefined)
exports.ContainerComponentID = new Element(5242907, 'ContainerComponentID', 'LO', '1', '0050001B', undefined)
exports.ContainerComponentLength = new Element(5242908, 'ContainerComponentLength', 'FD', '1', '0050001C', undefined)
exports.ContainerComponentDiameter = new Element(5242909, 'ContainerComponentDiameter', 'FD', '1', '0050001D', undefined)
exports.ContainerComponentDescription = new Element(5242910, 'ContainerComponentDescription', 'LO', '1', '0050001E', undefined)
exports.DeviceDescription = new Element(5242912, 'DeviceDescription', 'LO', '1', '00500020', undefined)
exports.ContrastBolusIngredientPercentByVolume = new Element(5373953, 'ContrastBolusIngredientPercentByVolume', 'FL', '1', '00520001', undefined)
exports.OCTFocalDistance = new Element(5373954, 'OCTFocalDistance', 'FD', '1', '00520002', undefined)
exports.BeamSpotSize = new Element(5373955, 'BeamSpotSize', 'FD', '1', '00520003', undefined)
exports.EffectiveRefractiveIndex = new Element(5373956, 'EffectiveRefractiveIndex', 'FD', '1', '00520004', undefined)
exports.OCTAcquisitionDomain = new Element(5373958, 'OCTAcquisitionDomain', 'CS', '1', '00520006', undefined)
exports.OCTOpticalCenterWavelength = new Element(5373959, 'OCTOpticalCenterWavelength', 'FD', '1', '00520007', undefined)
exports.AxialResolution = new Element(5373960, 'AxialResolution', 'FD', '1', '00520008', undefined)
exports.RangingDepth = new Element(5373961, 'RangingDepth', 'FD', '1', '00520009', undefined)
exports.ALineRate = new Element(5373969, 'ALineRate', 'FD', '1', '00520011', undefined)
exports.ALinesPerFrame = new Element(5373970, 'ALinesPerFrame', 'US', '1', '00520012', undefined)
exports.CatheterRotationalRate = new Element(5373971, 'CatheterRotationalRate', 'FD', '1', '00520013', undefined)
exports.ALinePixelSpacing = new Element(5373972, 'ALinePixelSpacing', 'FD', '1', '00520014', undefined)
exports.ModeOfPercutaneousAccessSequence = new Element(5373974, 'ModeOfPercutaneousAccessSequence', 'SQ', '1', '00520016', undefined)
exports.IntravascularOCTFrameTypeSequence = new Element(5373989, 'IntravascularOCTFrameTypeSequence', 'SQ', '1', '00520025', undefined)
exports.OCTZOffsetApplied = new Element(5373990, 'OCTZOffsetApplied', 'CS', '1', '00520026', undefined)
exports.IntravascularFrameContentSequence = new Element(5373991, 'IntravascularFrameContentSequence', 'SQ', '1', '00520027', undefined)
exports.IntravascularLongitudinalDistance = new Element(5373992, 'IntravascularLongitudinalDistance', 'FD', '1', '00520028', undefined)
exports.IntravascularOCTFrameContentSequence = new Element(5373993, 'IntravascularOCTFrameContentSequence', 'SQ', '1', '00520029', undefined)
exports.OCTZOffsetCorrection = new Element(5374000, 'OCTZOffsetCorrection', 'SS', '1', '00520030', undefined)
exports.CatheterDirectionOfRotation = new Element(5374001, 'CatheterDirectionOfRotation', 'CS', '1', '00520031', undefined)
exports.SeamLineLocation = new Element(5374003, 'SeamLineLocation', 'FD', '1', '00520033', undefined)
exports.FirstALineLocation = new Element(5374004, 'FirstALineLocation', 'FD', '1', '00520034', undefined)
exports.SeamLineIndex = new Element(5374006, 'SeamLineIndex', 'US', '1', '00520036', undefined)
exports.NumberOfPaddedALines = new Element(5374008, 'NumberOfPaddedALines', 'US', '1', '00520038', undefined)
exports.InterpolationType = new Element(5374009, 'InterpolationType', 'CS', '1', '00520039', undefined)
exports.RefractiveIndexApplied = new Element(5374010, 'RefractiveIndexApplied', 'CS', '1', '0052003A', undefined)
exports.EnergyWindowVector = new Element(5505040, 'EnergyWindowVector', 'US', '1-n', '00540010', undefined)
exports.NumberOfEnergyWindows = new Element(5505041, 'NumberOfEnergyWindows', 'US', '1', '00540011', undefined)
exports.EnergyWindowInformationSequence = new Element(5505042, 'EnergyWindowInformationSequence', 'SQ', '1', '00540012', undefined)
exports.EnergyWindowRangeSequence = new Element(5505043, 'EnergyWindowRangeSequence', 'SQ', '1', '00540013', undefined)
exports.EnergyWindowLowerLimit = new Element(5505044, 'EnergyWindowLowerLimit', 'DS', '1', '00540014', undefined)
exports.EnergyWindowUpperLimit = new Element(5505045, 'EnergyWindowUpperLimit', 'DS', '1', '00540015', undefined)
exports.RadiopharmaceuticalInformationSequence = new Element(5505046, 'RadiopharmaceuticalInformationSequence', 'SQ', '1', '00540016', undefined)
exports.ResidualSyringeCounts = new Element(5505047, 'ResidualSyringeCounts', 'IS', '1', '00540017', undefined)
exports.EnergyWindowName = new Element(5505048, 'EnergyWindowName', 'SH', '1', '00540018', undefined)
exports.DetectorVector = new Element(5505056, 'DetectorVector', 'US', '1-n', '00540020', undefined)
exports.NumberOfDetectors = new Element(5505057, 'NumberOfDetectors', 'US', '1', '00540021', undefined)
exports.DetectorInformationSequence = new Element(5505058, 'DetectorInformationSequence', 'SQ', '1', '00540022', undefined)
exports.PhaseVector = new Element(5505072, 'PhaseVector', 'US', '1-n', '00540030', undefined)
exports.NumberOfPhases = new Element(5505073, 'NumberOfPhases', 'US', '1', '00540031', undefined)
exports.PhaseInformationSequence = new Element(5505074, 'PhaseInformationSequence', 'SQ', '1', '00540032', undefined)
exports.NumberOfFramesInPhase = new Element(5505075, 'NumberOfFramesInPhase', 'US', '1', '00540033', undefined)
exports.PhaseDelay = new Element(5505078, 'PhaseDelay', 'IS', '1', '00540036', undefined)
exports.PauseBetweenFrames = new Element(5505080, 'PauseBetweenFrames', 'IS', '1', '00540038', undefined)
exports.PhaseDescription = new Element(5505081, 'PhaseDescription', 'CS', '1', '00540039', undefined)
exports.RotationVector = new Element(5505104, 'RotationVector', 'US', '1-n', '00540050', undefined)
exports.NumberOfRotations = new Element(5505105, 'NumberOfRotations', 'US', '1', '00540051', undefined)
exports.RotationInformationSequence = new Element(5505106, 'RotationInformationSequence', 'SQ', '1', '00540052', undefined)
exports.NumberOfFramesInRotation = new Element(5505107, 'NumberOfFramesInRotation', 'US', '1', '00540053', undefined)
exports.RRIntervalVector = new Element(5505120, 'RRIntervalVector', 'US', '1-n', '00540060', undefined)
exports.NumberOfRRIntervals = new Element(5505121, 'NumberOfRRIntervals', 'US', '1', '00540061', undefined)
exports.GatedInformationSequence = new Element(5505122, 'GatedInformationSequence', 'SQ', '1', '00540062', undefined)
exports.DataInformationSequence = new Element(5505123, 'DataInformationSequence', 'SQ', '1', '00540063', undefined)
exports.TimeSlotVector = new Element(5505136, 'TimeSlotVector', 'US', '1-n', '00540070', undefined)
exports.NumberOfTimeSlots = new Element(5505137, 'NumberOfTimeSlots', 'US', '1', '00540071', undefined)
exports.TimeSlotInformationSequence = new Element(5505138, 'TimeSlotInformationSequence', 'SQ', '1', '00540072', undefined)
exports.TimeSlotTime = new Element(5505139, 'TimeSlotTime', 'DS', '1', '00540073', undefined)
exports.SliceVector = new Element(5505152, 'SliceVector', 'US', '1-n', '00540080', undefined)
exports.NumberOfSlices = new Element(5505153, 'NumberOfSlices', 'US', '1', '00540081', undefined)
exports.AngularViewVector = new Element(5505168, 'AngularViewVector', 'US', '1-n', '00540090', undefined)
exports.TimeSliceVector = new Element(5505280, 'TimeSliceVector', 'US', '1-n', '00540100', undefined)
exports.NumberOfTimeSlices = new Element(5505281, 'NumberOfTimeSlices', 'US', '1', '00540101', undefined)
exports.StartAngle = new Element(5505536, 'StartAngle', 'DS', '1', '00540200', undefined)
exports.TypeOfDetectorMotion = new Element(5505538, 'TypeOfDetectorMotion', 'CS', '1', '00540202', undefined)
exports.TriggerVector = new Element(5505552, 'TriggerVector', 'IS', '1-n', '00540210', undefined)
exports.NumberOfTriggersInPhase = new Element(5505553, 'NumberOfTriggersInPhase', 'US', '1', '00540211', undefined)
exports.ViewCodeSequence = new Element(5505568, 'ViewCodeSequence', 'SQ', '1', '00540220', undefined)
exports.ViewModifierCodeSequence = new Element(5505570, 'ViewModifierCodeSequence', 'SQ', '1', '00540222', undefined)
exports.RadionuclideCodeSequence = new Element(5505792, 'RadionuclideCodeSequence', 'SQ', '1', '00540300', undefined)
exports.AdministrationRouteCodeSequence = new Element(5505794, 'AdministrationRouteCodeSequence', 'SQ', '1', '00540302', undefined)
exports.RadiopharmaceuticalCodeSequence = new Element(5505796, 'RadiopharmaceuticalCodeSequence', 'SQ', '1', '00540304', undefined)
exports.CalibrationDataSequence = new Element(5505798, 'CalibrationDataSequence', 'SQ', '1', '00540306', undefined)
exports.EnergyWindowNumber = new Element(5505800, 'EnergyWindowNumber', 'US', '1', '00540308', undefined)
exports.ImageID = new Element(5506048, 'ImageID', 'SH', '1', '00540400', undefined)
exports.PatientOrientationCodeSequence = new Element(5506064, 'PatientOrientationCodeSequence', 'SQ', '1', '00540410', undefined)
exports.PatientOrientationModifierCodeSequence = new Element(5506066, 'PatientOrientationModifierCodeSequence', 'SQ', '1', '00540412', undefined)
exports.PatientGantryRelationshipCodeSequence = new Element(5506068, 'PatientGantryRelationshipCodeSequence', 'SQ', '1', '00540414', undefined)
exports.SliceProgressionDirection = new Element(5506304, 'SliceProgressionDirection', 'CS', '1', '00540500', undefined)
exports.ScanProgressionDirection = new Element(5506305, 'ScanProgressionDirection', 'CS', '1', '00540501', undefined)
exports.SeriesType = new Element(5509120, 'SeriesType', 'CS', '2', '00541000', undefined)
exports.Units = new Element(5509121, 'Units', 'CS', '1', '00541001', undefined)
exports.CountsSource = new Element(5509122, 'CountsSource', 'CS', '1', '00541002', undefined)
exports.ReprojectionMethod = new Element(5509124, 'ReprojectionMethod', 'CS', '1', '00541004', undefined)
exports.SUVType = new Element(5509126, 'SUVType', 'CS', '1', '00541006', undefined)
exports.RandomsCorrectionMethod = new Element(5509376, 'RandomsCorrectionMethod', 'CS', '1', '00541100', undefined)
exports.AttenuationCorrectionMethod = new Element(5509377, 'AttenuationCorrectionMethod', 'LO', '1', '00541101', undefined)
exports.DecayCorrection = new Element(5509378, 'DecayCorrection', 'CS', '1', '00541102', undefined)
exports.ReconstructionMethod = new Element(5509379, 'ReconstructionMethod', 'LO', '1', '00541103', undefined)
exports.DetectorLinesOfResponseUsed = new Element(5509380, 'DetectorLinesOfResponseUsed', 'LO', '1', '00541104', undefined)
exports.ScatterCorrectionMethod = new Element(5509381, 'ScatterCorrectionMethod', 'LO', '1', '00541105', undefined)
exports.AxialAcceptance = new Element(5509632, 'AxialAcceptance', 'DS', '1', '00541200', undefined)
exports.AxialMash = new Element(5509633, 'AxialMash', 'IS', '2', '00541201', undefined)
exports.TransverseMash = new Element(5509634, 'TransverseMash', 'IS', '1', '00541202', undefined)
exports.DetectorElementSize = new Element(5509635, 'DetectorElementSize', 'DS', '2', '00541203', undefined)
exports.CoincidenceWindowWidth = new Element(5509648, 'CoincidenceWindowWidth', 'DS', '1', '00541210', undefined)
exports.SecondaryCountsType = new Element(5509664, 'SecondaryCountsType', 'CS', '1-n', '00541220', undefined)
exports.FrameReferenceTime = new Element(5509888, 'FrameReferenceTime', 'DS', '1', '00541300', undefined)
exports.PrimaryPromptsCountsAccumulated = new Element(5509904, 'PrimaryPromptsCountsAccumulated', 'IS', '1', '00541310', undefined)
exports.SecondaryCountsAccumulated = new Element(5509905, 'SecondaryCountsAccumulated', 'IS', '1-n', '00541311', undefined)
exports.SliceSensitivityFactor = new Element(5509920, 'SliceSensitivityFactor', 'DS', '1', '00541320', undefined)
exports.DecayFactor = new Element(5509921, 'DecayFactor', 'DS', '1', '00541321', undefined)
exports.DoseCalibrationFactor = new Element(5509922, 'DoseCalibrationFactor', 'DS', '1', '00541322', undefined)
exports.ScatterFractionFactor = new Element(5509923, 'ScatterFractionFactor', 'DS', '1', '00541323', undefined)
exports.DeadTimeFactor = new Element(5509924, 'DeadTimeFactor', 'DS', '1', '00541324', undefined)
exports.ImageIndex = new Element(5509936, 'ImageIndex', 'US', '1', '00541330', undefined)
exports.CountsIncluded = new Element(5510144, 'CountsIncluded', 'CS', '1-n', '00541400', true)
exports.DeadTimeCorrectionFlag = new Element(5510145, 'DeadTimeCorrectionFlag', 'CS', '1', '00541401', true)
exports.HistogramSequence = new Element(6303744, 'HistogramSequence', 'SQ', '1', '00603000', undefined)
exports.HistogramNumberOfBins = new Element(6303746, 'HistogramNumberOfBins', 'US', '1', '00603002', undefined)
exports.HistogramFirstBinValue = new Element(6303748, 'HistogramFirstBinValue', 'US or SS', '1', '00603004', undefined)
exports.HistogramLastBinValue = new Element(6303750, 'HistogramLastBinValue', 'US or SS', '1', '00603006', undefined)
exports.HistogramBinWidth = new Element(6303752, 'HistogramBinWidth', 'US', '1', '00603008', undefined)
exports.HistogramExplanation = new Element(6303760, 'HistogramExplanation', 'LO', '1', '00603010', undefined)
exports.HistogramData = new Element(6303776, 'HistogramData', 'UL', '1-n', '00603020', undefined)
exports.SegmentationType = new Element(6422529, 'SegmentationType', 'CS', '1', '00620001', undefined)
exports.SegmentSequence = new Element(6422530, 'SegmentSequence', 'SQ', '1', '00620002', undefined)
exports.SegmentedPropertyCategoryCodeSequence = new Element(6422531, 'SegmentedPropertyCategoryCodeSequence', 'SQ', '1', '00620003', undefined)
exports.SegmentNumber = new Element(6422532, 'SegmentNumber', 'US', '1', '00620004', undefined)
exports.SegmentLabel = new Element(6422533, 'SegmentLabel', 'LO', '1', '00620005', undefined)
exports.SegmentDescription = new Element(6422534, 'SegmentDescription', 'ST', '1', '00620006', undefined)
exports.SegmentAlgorithmType = new Element(6422536, 'SegmentAlgorithmType', 'CS', '1', '00620008', undefined)
exports.SegmentAlgorithmName = new Element(6422537, 'SegmentAlgorithmName', 'LO', '1', '00620009', undefined)
exports.SegmentIdentificationSequence = new Element(6422538, 'SegmentIdentificationSequence', 'SQ', '1', '0062000A', undefined)
exports.ReferencedSegmentNumber = new Element(6422539, 'ReferencedSegmentNumber', 'US', '1-n', '0062000B', undefined)
exports.RecommendedDisplayGrayscaleValue = new Element(6422540, 'RecommendedDisplayGrayscaleValue', 'US', '1', '0062000C', undefined)
exports.RecommendedDisplayCIELabValue = new Element(6422541, 'RecommendedDisplayCIELabValue', 'US', '3', '0062000D', undefined)
exports.MaximumFractionalValue = new Element(6422542, 'MaximumFractionalValue', 'US', '1', '0062000E', undefined)
exports.SegmentedPropertyTypeCodeSequence = new Element(6422543, 'SegmentedPropertyTypeCodeSequence', 'SQ', '1', '0062000F', undefined)
exports.SegmentationFractionalType = new Element(6422544, 'SegmentationFractionalType', 'CS', '1', '00620010', undefined)
exports.SegmentedPropertyTypeModifierCodeSequence = new Element(6422545, 'SegmentedPropertyTypeModifierCodeSequence', 'SQ', '1', '00620011', undefined)
exports.UsedSegmentsSequence = new Element(6422546, 'UsedSegmentsSequence', 'SQ', '1', '00620012', undefined)
exports.DeformableRegistrationSequence = new Element(6553602, 'DeformableRegistrationSequence', 'SQ', '1', '00640002', undefined)
exports.SourceFrameOfReferenceUID = new Element(6553603, 'SourceFrameOfReferenceUID', 'UI', '1', '00640003', undefined)
exports.DeformableRegistrationGridSequence = new Element(6553605, 'DeformableRegistrationGridSequence', 'SQ', '1', '00640005', undefined)
exports.GridDimensions = new Element(6553607, 'GridDimensions', 'UL', '3', '00640007', undefined)
exports.GridResolution = new Element(6553608, 'GridResolution', 'FD', '3', '00640008', undefined)
exports.VectorGridData = new Element(6553609, 'VectorGridData', 'OF', '1', '00640009', undefined)
exports.PreDeformationMatrixRegistrationSequence = new Element(6553615, 'PreDeformationMatrixRegistrationSequence', 'SQ', '1', '0064000F', undefined)
exports.PostDeformationMatrixRegistrationSequence = new Element(6553616, 'PostDeformationMatrixRegistrationSequence', 'SQ', '1', '00640010', undefined)
exports.NumberOfSurfaces = new Element(6684673, 'NumberOfSurfaces', 'UL', '1', '00660001', undefined)
exports.SurfaceSequence = new Element(6684674, 'SurfaceSequence', 'SQ', '1', '00660002', undefined)
exports.SurfaceNumber = new Element(6684675, 'SurfaceNumber', 'UL', '1', '00660003', undefined)
exports.SurfaceComments = new Element(6684676, 'SurfaceComments', 'LT', '1', '00660004', undefined)
exports.SurfaceProcessing = new Element(6684681, 'SurfaceProcessing', 'CS', '1', '00660009', undefined)
exports.SurfaceProcessingRatio = new Element(6684682, 'SurfaceProcessingRatio', 'FL', '1', '0066000A', undefined)
exports.SurfaceProcessingDescription = new Element(6684683, 'SurfaceProcessingDescription', 'LO', '1', '0066000B', undefined)
exports.RecommendedPresentationOpacity = new Element(6684684, 'RecommendedPresentationOpacity', 'FL', '1', '0066000C', undefined)
exports.RecommendedPresentationType = new Element(6684685, 'RecommendedPresentationType', 'CS', '1', '0066000D', undefined)
exports.FiniteVolume = new Element(6684686, 'FiniteVolume', 'CS', '1', '0066000E', undefined)
exports.Manifold = new Element(6684688, 'Manifold', 'CS', '1', '00660010', undefined)
exports.SurfacePointsSequence = new Element(6684689, 'SurfacePointsSequence', 'SQ', '1', '00660011', undefined)
exports.SurfacePointsNormalsSequence = new Element(6684690, 'SurfacePointsNormalsSequence', 'SQ', '1', '00660012', undefined)
exports.SurfaceMeshPrimitivesSequence = new Element(6684691, 'SurfaceMeshPrimitivesSequence', 'SQ', '1', '00660013', undefined)
exports.NumberOfSurfacePoints = new Element(6684693, 'NumberOfSurfacePoints', 'UL', '1', '00660015', undefined)
exports.PointCoordinatesData = new Element(6684694, 'PointCoordinatesData', 'OF', '1', '00660016', undefined)
exports.PointPositionAccuracy = new Element(6684695, 'PointPositionAccuracy', 'FL', '3', '00660017', undefined)
exports.MeanPointDistance = new Element(6684696, 'MeanPointDistance', 'FL', '1', '00660018', undefined)
exports.MaximumPointDistance = new Element(6684697, 'MaximumPointDistance', 'FL', '1', '00660019', undefined)
exports.PointsBoundingBoxCoordinates = new Element(6684698, 'PointsBoundingBoxCoordinates', 'FL', '6', '0066001A', undefined)
exports.AxisOfRotation = new Element(6684699, 'AxisOfRotation', 'FL', '3', '0066001B', undefined)
exports.CenterOfRotation = new Element(6684700, 'CenterOfRotation', 'FL', '3', '0066001C', undefined)
exports.NumberOfVectors = new Element(6684702, 'NumberOfVectors', 'UL', '1', '0066001E', undefined)
exports.VectorDimensionality = new Element(6684703, 'VectorDimensionality', 'US', '1', '0066001F', undefined)
exports.VectorAccuracy = new Element(6684704, 'VectorAccuracy', 'FL', '1-n', '00660020', undefined)
exports.VectorCoordinateData = new Element(6684705, 'VectorCoordinateData', 'OF', '1', '00660021', undefined)
exports.TrianglePointIndexList = new Element(6684707, 'TrianglePointIndexList', 'OW', '1', '00660023', undefined)
exports.EdgePointIndexList = new Element(6684708, 'EdgePointIndexList', 'OW', '1', '00660024', undefined)
exports.VertexPointIndexList = new Element(6684709, 'VertexPointIndexList', 'OW', '1', '00660025', undefined)
exports.TriangleStripSequence = new Element(6684710, 'TriangleStripSequence', 'SQ', '1', '00660026', undefined)
exports.TriangleFanSequence = new Element(6684711, 'TriangleFanSequence', 'SQ', '1', '00660027', undefined)
exports.LineSequence = new Element(6684712, 'LineSequence', 'SQ', '1', '00660028', undefined)
exports.PrimitivePointIndexList = new Element(6684713, 'PrimitivePointIndexList', 'OW', '1', '00660029', undefined)
exports.SurfaceCount = new Element(6684714, 'SurfaceCount', 'UL', '1', '0066002A', undefined)
exports.ReferencedSurfaceSequence = new Element(6684715, 'ReferencedSurfaceSequence', 'SQ', '1', '0066002B', undefined)
exports.ReferencedSurfaceNumber = new Element(6684716, 'ReferencedSurfaceNumber', 'UL', '1', '0066002C', undefined)
exports.SegmentSurfaceGenerationAlgorithmIdentificationSequence = new Element(6684717, 'SegmentSurfaceGenerationAlgorithmIdentificationSequence', 'SQ', '1', '0066002D', undefined)
exports.SegmentSurfaceSourceInstanceSequence = new Element(6684718, 'SegmentSurfaceSourceInstanceSequence', 'SQ', '1', '0066002E', undefined)
exports.AlgorithmFamilyCodeSequence = new Element(6684719, 'AlgorithmFamilyCodeSequence', 'SQ', '1', '0066002F', undefined)
exports.AlgorithmNameCodeSequence = new Element(6684720, 'AlgorithmNameCodeSequence', 'SQ', '1', '00660030', undefined)
exports.AlgorithmVersion = new Element(6684721, 'AlgorithmVersion', 'LO', '1', '00660031', undefined)
exports.AlgorithmParameters = new Element(6684722, 'AlgorithmParameters', 'LT', '1', '00660032', undefined)
exports.FacetSequence = new Element(6684724, 'FacetSequence', 'SQ', '1', '00660034', undefined)
exports.SurfaceProcessingAlgorithmIdentificationSequence = new Element(6684725, 'SurfaceProcessingAlgorithmIdentificationSequence', 'SQ', '1', '00660035', undefined)
exports.AlgorithmName = new Element(6684726, 'AlgorithmName', 'LO', '1', '00660036', undefined)
exports.RecommendedPointRadius = new Element(6684727, 'RecommendedPointRadius', 'FL', '1', '00660037', undefined)
exports.RecommendedLineThickness = new Element(6684728, 'RecommendedLineThickness', 'FL', '1', '00660038', undefined)
exports.ImplantSize = new Element(6840848, 'ImplantSize', 'LO', '1', '00686210', undefined)
exports.ImplantTemplateVersion = new Element(6840865, 'ImplantTemplateVersion', 'LO', '1', '00686221', undefined)
exports.ReplacedImplantTemplateSequence = new Element(6840866, 'ReplacedImplantTemplateSequence', 'SQ', '1', '00686222', undefined)
exports.ImplantType = new Element(6840867, 'ImplantType', 'CS', '1', '00686223', undefined)
exports.DerivationImplantTemplateSequence = new Element(6840868, 'DerivationImplantTemplateSequence', 'SQ', '1', '00686224', undefined)
exports.OriginalImplantTemplateSequence = new Element(6840869, 'OriginalImplantTemplateSequence', 'SQ', '1', '00686225', undefined)
exports.EffectiveDateTime = new Element(6840870, 'EffectiveDateTime', 'DT', '1', '00686226', undefined)
exports.ImplantTargetAnatomySequence = new Element(6840880, 'ImplantTargetAnatomySequence', 'SQ', '1', '00686230', undefined)
exports.InformationFromManufacturerSequence = new Element(6840928, 'InformationFromManufacturerSequence', 'SQ', '1', '00686260', undefined)
exports.NotificationFromManufacturerSequence = new Element(6840933, 'NotificationFromManufacturerSequence', 'SQ', '1', '00686265', undefined)
exports.InformationIssueDateTime = new Element(6840944, 'InformationIssueDateTime', 'DT', '1', '00686270', undefined)
exports.InformationSummary = new Element(6840960, 'InformationSummary', 'ST', '1', '00686280', undefined)
exports.ImplantRegulatoryDisapprovalCodeSequence = new Element(6840992, 'ImplantRegulatoryDisapprovalCodeSequence', 'SQ', '1', '006862A0', undefined)
exports.OverallTemplateSpatialTolerance = new Element(6840997, 'OverallTemplateSpatialTolerance', 'FD', '1', '006862A5', undefined)
exports.HPGLDocumentSequence = new Element(6841024, 'HPGLDocumentSequence', 'SQ', '1', '006862C0', undefined)
exports.HPGLDocumentID = new Element(6841040, 'HPGLDocumentID', 'US', '1', '006862D0', undefined)
exports.HPGLDocumentLabel = new Element(6841045, 'HPGLDocumentLabel', 'LO', '1', '006862D5', undefined)
exports.ViewOrientationCodeSequence = new Element(6841056, 'ViewOrientationCodeSequence', 'SQ', '1', '006862E0', undefined)
exports.ViewOrientationModifier = new Element(6841072, 'ViewOrientationModifier', 'FD', '9', '006862F0', undefined)
exports.HPGLDocumentScaling = new Element(6841074, 'HPGLDocumentScaling', 'FD', '1', '006862F2', undefined)
exports.HPGLDocument = new Element(6841088, 'HPGLDocument', 'OB', '1', '00686300', undefined)
exports.HPGLContourPenNumber = new Element(6841104, 'HPGLContourPenNumber', 'US', '1', '00686310', undefined)
exports.HPGLPenSequence = new Element(6841120, 'HPGLPenSequence', 'SQ', '1', '00686320', undefined)
exports.HPGLPenNumber = new Element(6841136, 'HPGLPenNumber', 'US', '1', '00686330', undefined)
exports.HPGLPenLabel = new Element(6841152, 'HPGLPenLabel', 'LO', '1', '00686340', undefined)
exports.HPGLPenDescription = new Element(6841157, 'HPGLPenDescription', 'ST', '1', '00686345', undefined)
exports.RecommendedRotationPoint = new Element(6841158, 'RecommendedRotationPoint', 'FD', '2', '00686346', undefined)
exports.BoundingRectangle = new Element(6841159, 'BoundingRectangle', 'FD', '4', '00686347', undefined)
exports.ImplantTemplate3DModelSurfaceNumber = new Element(6841168, 'ImplantTemplate3DModelSurfaceNumber', 'US', '1-n', '00686350', undefined)
exports.SurfaceModelDescriptionSequence = new Element(6841184, 'SurfaceModelDescriptionSequence', 'SQ', '1', '00686360', undefined)
exports.SurfaceModelLabel = new Element(6841216, 'SurfaceModelLabel', 'LO', '1', '00686380', undefined)
exports.SurfaceModelScalingFactor = new Element(6841232, 'SurfaceModelScalingFactor', 'FD', '1', '00686390', undefined)
exports.MaterialsCodeSequence = new Element(6841248, 'MaterialsCodeSequence', 'SQ', '1', '006863A0', undefined)
exports.CoatingMaterialsCodeSequence = new Element(6841252, 'CoatingMaterialsCodeSequence', 'SQ', '1', '006863A4', undefined)
exports.ImplantTypeCodeSequence = new Element(6841256, 'ImplantTypeCodeSequence', 'SQ', '1', '006863A8', undefined)
exports.FixationMethodCodeSequence = new Element(6841260, 'FixationMethodCodeSequence', 'SQ', '1', '006863AC', undefined)
exports.MatingFeatureSetsSequence = new Element(6841264, 'MatingFeatureSetsSequence', 'SQ', '1', '006863B0', undefined)
exports.MatingFeatureSetID = new Element(6841280, 'MatingFeatureSetID', 'US', '1', '006863C0', undefined)
exports.MatingFeatureSetLabel = new Element(6841296, 'MatingFeatureSetLabel', 'LO', '1', '006863D0', undefined)
exports.MatingFeatureSequence = new Element(6841312, 'MatingFeatureSequence', 'SQ', '1', '006863E0', undefined)
exports.MatingFeatureID = new Element(6841328, 'MatingFeatureID', 'US', '1', '006863F0', undefined)
exports.MatingFeatureDegreeOfFreedomSequence = new Element(6841344, 'MatingFeatureDegreeOfFreedomSequence', 'SQ', '1', '00686400', undefined)
exports.DegreeOfFreedomID = new Element(6841360, 'DegreeOfFreedomID', 'US', '1', '00686410', undefined)
exports.DegreeOfFreedomType = new Element(6841376, 'DegreeOfFreedomType', 'CS', '1', '00686420', undefined)
exports.TwoDMatingFeatureCoordinatesSequence = new Element(6841392, 'TwoDMatingFeatureCoordinatesSequence', 'SQ', '1', '00686430', undefined)
exports.ReferencedHPGLDocumentID = new Element(6841408, 'ReferencedHPGLDocumentID', 'US', '1', '00686440', undefined)
exports.TwoDMatingPoint = new Element(6841424, 'TwoDMatingPoint', 'FD', '2', '00686450', undefined)
exports.TwoDMatingAxes = new Element(6841440, 'TwoDMatingAxes', 'FD', '4', '00686460', undefined)
exports.TwoDDegreeOfFreedomSequence = new Element(6841456, 'TwoDDegreeOfFreedomSequence', 'SQ', '1', '00686470', undefined)
exports.ThreeDDegreeOfFreedomAxis = new Element(6841488, 'ThreeDDegreeOfFreedomAxis', 'FD', '3', '00686490', undefined)
exports.RangeOfFreedom = new Element(6841504, 'RangeOfFreedom', 'FD', '2', '006864A0', undefined)
exports.ThreeDMatingPoint = new Element(6841536, 'ThreeDMatingPoint', 'FD', '3', '006864C0', undefined)
exports.ThreeDMatingAxes = new Element(6841552, 'ThreeDMatingAxes', 'FD', '9', '006864D0', undefined)
exports.TwoDDegreeOfFreedomAxis = new Element(6841584, 'TwoDDegreeOfFreedomAxis', 'FD', '3', '006864F0', undefined)
exports.PlanningLandmarkPointSequence = new Element(6841600, 'PlanningLandmarkPointSequence', 'SQ', '1', '00686500', undefined)
exports.PlanningLandmarkLineSequence = new Element(6841616, 'PlanningLandmarkLineSequence', 'SQ', '1', '00686510', undefined)
exports.PlanningLandmarkPlaneSequence = new Element(6841632, 'PlanningLandmarkPlaneSequence', 'SQ', '1', '00686520', undefined)
exports.PlanningLandmarkID = new Element(6841648, 'PlanningLandmarkID', 'US', '1', '00686530', undefined)
exports.PlanningLandmarkDescription = new Element(6841664, 'PlanningLandmarkDescription', 'LO', '1', '00686540', undefined)
exports.PlanningLandmarkIdentificationCodeSequence = new Element(6841669, 'PlanningLandmarkIdentificationCodeSequence', 'SQ', '1', '00686545', undefined)
exports.TwoDPointCoordinatesSequence = new Element(6841680, 'TwoDPointCoordinatesSequence', 'SQ', '1', '00686550', undefined)
exports.TwoDPointCoordinates = new Element(6841696, 'TwoDPointCoordinates', 'FD', '2', '00686560', undefined)
exports.ThreeDPointCoordinates = new Element(6841744, 'ThreeDPointCoordinates', 'FD', '3', '00686590', undefined)
exports.TwoDLineCoordinatesSequence = new Element(6841760, 'TwoDLineCoordinatesSequence', 'SQ', '1', '006865A0', undefined)
exports.TwoDLineCoordinates = new Element(6841776, 'TwoDLineCoordinates', 'FD', '4', '006865B0', undefined)
exports.ThreeDLineCoordinates = new Element(6841808, 'ThreeDLineCoordinates', 'FD', '6', '006865D0', undefined)
exports.TwoDPlaneCoordinatesSequence = new Element(6841824, 'TwoDPlaneCoordinatesSequence', 'SQ', '1', '006865E0', undefined)
exports.TwoDPlaneIntersection = new Element(6841840, 'TwoDPlaneIntersection', 'FD', '4', '006865F0', undefined)
exports.ThreeDPlaneOrigin = new Element(6841872, 'ThreeDPlaneOrigin', 'FD', '3', '00686610', undefined)
exports.ThreeDPlaneNormal = new Element(6841888, 'ThreeDPlaneNormal', 'FD', '3', '00686620', undefined)
exports.GraphicAnnotationSequence = new Element(7340033, 'GraphicAnnotationSequence', 'SQ', '1', '00700001', undefined)
exports.GraphicLayer = new Element(7340034, 'GraphicLayer', 'CS', '1', '00700002', undefined)
exports.BoundingBoxAnnotationUnits = new Element(7340035, 'BoundingBoxAnnotationUnits', 'CS', '1', '00700003', undefined)
exports.AnchorPointAnnotationUnits = new Element(7340036, 'AnchorPointAnnotationUnits', 'CS', '1', '00700004', undefined)
exports.GraphicAnnotationUnits = new Element(7340037, 'GraphicAnnotationUnits', 'CS', '1', '00700005', undefined)
exports.UnformattedTextValue = new Element(7340038, 'UnformattedTextValue', 'ST', '1', '00700006', undefined)
exports.TextObjectSequence = new Element(7340040, 'TextObjectSequence', 'SQ', '1', '00700008', undefined)
exports.GraphicObjectSequence = new Element(7340041, 'GraphicObjectSequence', 'SQ', '1', '00700009', undefined)
exports.BoundingBoxTopLeftHandCorner = new Element(7340048, 'BoundingBoxTopLeftHandCorner', 'FL', '2', '00700010', undefined)
exports.BoundingBoxBottomRightHandCorner = new Element(7340049, 'BoundingBoxBottomRightHandCorner', 'FL', '2', '00700011', undefined)
exports.BoundingBoxTextHorizontalJustification = new Element(7340050, 'BoundingBoxTextHorizontalJustification', 'CS', '1', '00700012', undefined)
exports.AnchorPoint = new Element(7340052, 'AnchorPoint', 'FL', '2', '00700014', undefined)
exports.AnchorPointVisibility = new Element(7340053, 'AnchorPointVisibility', 'CS', '1', '00700015', undefined)
exports.GraphicDimensions = new Element(7340064, 'GraphicDimensions', 'US', '1', '00700020', undefined)
exports.NumberOfGraphicPoints = new Element(7340065, 'NumberOfGraphicPoints', 'US', '1', '00700021', undefined)
exports.GraphicData = new Element(7340066, 'GraphicData', 'FL', '2-n', '00700022', undefined)
exports.GraphicType = new Element(7340067, 'GraphicType', 'CS', '1', '00700023', undefined)
exports.GraphicFilled = new Element(7340068, 'GraphicFilled', 'CS', '1', '00700024', undefined)
exports.ImageRotationRetired = new Element(7340096, 'ImageRotationRetired', 'IS', '1', '00700040', true)
exports.ImageHorizontalFlip = new Element(7340097, 'ImageHorizontalFlip', 'CS', '1', '00700041', undefined)
exports.ImageRotation = new Element(7340098, 'ImageRotation', 'US', '1', '00700042', undefined)
exports.DisplayedAreaTopLeftHandCornerTrial = new Element(7340112, 'DisplayedAreaTopLeftHandCornerTrial', 'US', '2', '00700050', true)
exports.DisplayedAreaBottomRightHandCornerTrial = new Element(7340113, 'DisplayedAreaBottomRightHandCornerTrial', 'US', '2', '00700051', true)
exports.DisplayedAreaTopLeftHandCorner = new Element(7340114, 'DisplayedAreaTopLeftHandCorner', 'SL', '2', '00700052', undefined)
exports.DisplayedAreaBottomRightHandCorner = new Element(7340115, 'DisplayedAreaBottomRightHandCorner', 'SL', '2', '00700053', undefined)
exports.DisplayedAreaSelectionSequence = new Element(7340122, 'DisplayedAreaSelectionSequence', 'SQ', '1', '0070005A', undefined)
exports.GraphicLayerSequence = new Element(7340128, 'GraphicLayerSequence', 'SQ', '1', '00700060', undefined)
exports.GraphicLayerOrder = new Element(7340130, 'GraphicLayerOrder', 'IS', '1', '00700062', undefined)
exports.GraphicLayerRecommendedDisplayGrayscaleValue = new Element(7340134, 'GraphicLayerRecommendedDisplayGrayscaleValue', 'US', '1', '00700066', undefined)
exports.GraphicLayerRecommendedDisplayRGBValue = new Element(7340135, 'GraphicLayerRecommendedDisplayRGBValue', 'US', '3', '00700067', true)
exports.GraphicLayerDescription = new Element(7340136, 'GraphicLayerDescription', 'LO', '1', '00700068', undefined)
exports.ContentLabel = new Element(7340160, 'ContentLabel', 'CS', '1', '00700080', undefined)
exports.ContentDescription = new Element(7340161, 'ContentDescription', 'LO', '1', '00700081', undefined)
exports.PresentationCreationDate = new Element(7340162, 'PresentationCreationDate', 'DA', '1', '00700082', undefined)
exports.PresentationCreationTime = new Element(7340163, 'PresentationCreationTime', 'TM', '1', '00700083', undefined)
exports.ContentCreatorName = new Element(7340164, 'ContentCreatorName', 'PN', '1', '00700084', undefined)
exports.ContentCreatorIdentificationCodeSequence = new Element(7340166, 'ContentCreatorIdentificationCodeSequence', 'SQ', '1', '00700086', undefined)
exports.AlternateContentDescriptionSequence = new Element(7340167, 'AlternateContentDescriptionSequence', 'SQ', '1', '00700087', undefined)
exports.PresentationSizeMode = new Element(7340288, 'PresentationSizeMode', 'CS', '1', '00700100', undefined)
exports.PresentationPixelSpacing = new Element(7340289, 'PresentationPixelSpacing', 'DS', '2', '00700101', undefined)
exports.PresentationPixelAspectRatio = new Element(7340290, 'PresentationPixelAspectRatio', 'IS', '2', '00700102', undefined)
exports.PresentationPixelMagnificationRatio = new Element(7340291, 'PresentationPixelMagnificationRatio', 'FL', '1', '00700103', undefined)
exports.GraphicGroupLabel = new Element(7340551, 'GraphicGroupLabel', 'LO', '1', '00700207', undefined)
exports.GraphicGroupDescription = new Element(7340552, 'GraphicGroupDescription', 'ST', '1', '00700208', undefined)
exports.CompoundGraphicSequence = new Element(7340553, 'CompoundGraphicSequence', 'SQ', '1', '00700209', undefined)
exports.CompoundGraphicInstanceID = new Element(7340582, 'CompoundGraphicInstanceID', 'UL', '1', '00700226', undefined)
exports.FontName = new Element(7340583, 'FontName', 'LO', '1', '00700227', undefined)
exports.FontNameType = new Element(7340584, 'FontNameType', 'CS', '1', '00700228', undefined)
exports.CSSFontName = new Element(7340585, 'CSSFontName', 'LO', '1', '00700229', undefined)
exports.RotationAngle = new Element(7340592, 'RotationAngle', 'FD', '1', '00700230', undefined)
exports.TextStyleSequence = new Element(7340593, 'TextStyleSequence', 'SQ', '1', '00700231', undefined)
exports.LineStyleSequence = new Element(7340594, 'LineStyleSequence', 'SQ', '1', '00700232', undefined)
exports.FillStyleSequence = new Element(7340595, 'FillStyleSequence', 'SQ', '1', '00700233', undefined)
exports.GraphicGroupSequence = new Element(7340596, 'GraphicGroupSequence', 'SQ', '1', '00700234', undefined)
exports.TextColorCIELabValue = new Element(7340609, 'TextColorCIELabValue', 'US', '3', '00700241', undefined)
exports.HorizontalAlignment = new Element(7340610, 'HorizontalAlignment', 'CS', '1', '00700242', undefined)
exports.VerticalAlignment = new Element(7340611, 'VerticalAlignment', 'CS', '1', '00700243', undefined)
exports.ShadowStyle = new Element(7340612, 'ShadowStyle', 'CS', '1', '00700244', undefined)
exports.ShadowOffsetX = new Element(7340613, 'ShadowOffsetX', 'FL', '1', '00700245', undefined)
exports.ShadowOffsetY = new Element(7340614, 'ShadowOffsetY', 'FL', '1', '00700246', undefined)
exports.ShadowColorCIELabValue = new Element(7340615, 'ShadowColorCIELabValue', 'US', '3', '00700247', undefined)
exports.Underlined = new Element(7340616, 'Underlined', 'CS', '1', '00700248', undefined)
exports.Bold = new Element(7340617, 'Bold', 'CS', '1', '00700249', undefined)
exports.Italic = new Element(7340624, 'Italic', 'CS', '1', '00700250', undefined)
exports.PatternOnColorCIELabValue = new Element(7340625, 'PatternOnColorCIELabValue', 'US', '3', '00700251', undefined)
exports.PatternOffColorCIELabValue = new Element(7340626, 'PatternOffColorCIELabValue', 'US', '3', '00700252', undefined)
exports.LineThickness = new Element(7340627, 'LineThickness', 'FL', '1', '00700253', undefined)
exports.LineDashingStyle = new Element(7340628, 'LineDashingStyle', 'CS', '1', '00700254', undefined)
exports.LinePattern = new Element(7340629, 'LinePattern', 'UL', '1', '00700255', undefined)
exports.FillPattern = new Element(7340630, 'FillPattern', 'OB', '1', '00700256', undefined)
exports.FillMode = new Element(7340631, 'FillMode', 'CS', '1', '00700257', undefined)
exports.ShadowOpacity = new Element(7340632, 'ShadowOpacity', 'FL', '1', '00700258', undefined)
exports.GapLength = new Element(7340641, 'GapLength', 'FL', '1', '00700261', undefined)
exports.DiameterOfVisibility = new Element(7340642, 'DiameterOfVisibility', 'FL', '1', '00700262', undefined)
exports.RotationPoint = new Element(7340659, 'RotationPoint', 'FL', '2', '00700273', undefined)
exports.TickAlignment = new Element(7340660, 'TickAlignment', 'CS', '1', '00700274', undefined)
exports.ShowTickLabel = new Element(7340664, 'ShowTickLabel', 'CS', '1', '00700278', undefined)
exports.TickLabelAlignment = new Element(7340665, 'TickLabelAlignment', 'CS', '1', '00700279', undefined)
exports.CompoundGraphicUnits = new Element(7340674, 'CompoundGraphicUnits', 'CS', '1', '00700282', undefined)
exports.PatternOnOpacity = new Element(7340676, 'PatternOnOpacity', 'FL', '1', '00700284', undefined)
exports.PatternOffOpacity = new Element(7340677, 'PatternOffOpacity', 'FL', '1', '00700285', undefined)
exports.MajorTicksSequence = new Element(7340679, 'MajorTicksSequence', 'SQ', '1', '00700287', undefined)
exports.TickPosition = new Element(7340680, 'TickPosition', 'FL', '1', '00700288', undefined)
exports.TickLabel = new Element(7340681, 'TickLabel', 'SH', '1', '00700289', undefined)
exports.CompoundGraphicType = new Element(7340692, 'CompoundGraphicType', 'CS', '1', '00700294', undefined)
exports.GraphicGroupID = new Element(7340693, 'GraphicGroupID', 'UL', '1', '00700295', undefined)
exports.ShapeType = new Element(7340806, 'ShapeType', 'CS', '1', '00700306', undefined)
exports.RegistrationSequence = new Element(7340808, 'RegistrationSequence', 'SQ', '1', '00700308', undefined)
exports.MatrixRegistrationSequence = new Element(7340809, 'MatrixRegistrationSequence', 'SQ', '1', '00700309', undefined)
exports.MatrixSequence = new Element(7340810, 'MatrixSequence', 'SQ', '1', '0070030A', undefined)
exports.FrameOfReferenceTransformationMatrixType = new Element(7340812, 'FrameOfReferenceTransformationMatrixType', 'CS', '1', '0070030C', undefined)
exports.RegistrationTypeCodeSequence = new Element(7340813, 'RegistrationTypeCodeSequence', 'SQ', '1', '0070030D', undefined)
exports.FiducialDescription = new Element(7340815, 'FiducialDescription', 'ST', '1', '0070030F', undefined)
exports.FiducialIdentifier = new Element(7340816, 'FiducialIdentifier', 'SH', '1', '00700310', undefined)
exports.FiducialIdentifierCodeSequence = new Element(7340817, 'FiducialIdentifierCodeSequence', 'SQ', '1', '00700311', undefined)
exports.ContourUncertaintyRadius = new Element(7340818, 'ContourUncertaintyRadius', 'FD', '1', '00700312', undefined)
exports.UsedFiducialsSequence = new Element(7340820, 'UsedFiducialsSequence', 'SQ', '1', '00700314', undefined)
exports.GraphicCoordinatesDataSequence = new Element(7340824, 'GraphicCoordinatesDataSequence', 'SQ', '1', '00700318', undefined)
exports.FiducialUID = new Element(7340826, 'FiducialUID', 'UI', '1', '0070031A', undefined)
exports.FiducialSetSequence = new Element(7340828, 'FiducialSetSequence', 'SQ', '1', '0070031C', undefined)
exports.FiducialSequence = new Element(7340830, 'FiducialSequence', 'SQ', '1', '0070031E', undefined)
exports.GraphicLayerRecommendedDisplayCIELabValue = new Element(7341057, 'GraphicLayerRecommendedDisplayCIELabValue', 'US', '3', '00700401', undefined)
exports.BlendingSequence = new Element(7341058, 'BlendingSequence', 'SQ', '1', '00700402', undefined)
exports.RelativeOpacity = new Element(7341059, 'RelativeOpacity', 'FL', '1', '00700403', undefined)
exports.ReferencedSpatialRegistrationSequence = new Element(7341060, 'ReferencedSpatialRegistrationSequence', 'SQ', '1', '00700404', undefined)
exports.BlendingPosition = new Element(7341061, 'BlendingPosition', 'CS', '1', '00700405', undefined)
exports.HangingProtocolName = new Element(7471106, 'HangingProtocolName', 'SH', '1', '00720002', undefined)
exports.HangingProtocolDescription = new Element(7471108, 'HangingProtocolDescription', 'LO', '1', '00720004', undefined)
exports.HangingProtocolLevel = new Element(7471110, 'HangingProtocolLevel', 'CS', '1', '00720006', undefined)
exports.HangingProtocolCreator = new Element(7471112, 'HangingProtocolCreator', 'LO', '1', '00720008', undefined)
exports.HangingProtocolCreationDateTime = new Element(7471114, 'HangingProtocolCreationDateTime', 'DT', '1', '0072000A', undefined)
exports.HangingProtocolDefinitionSequence = new Element(7471116, 'HangingProtocolDefinitionSequence', 'SQ', '1', '0072000C', undefined)
exports.HangingProtocolUserIdentificationCodeSequence = new Element(7471118, 'HangingProtocolUserIdentificationCodeSequence', 'SQ', '1', '0072000E', undefined)
exports.HangingProtocolUserGroupName = new Element(7471120, 'HangingProtocolUserGroupName', 'LO', '1', '00720010', undefined)
exports.SourceHangingProtocolSequence = new Element(7471122, 'SourceHangingProtocolSequence', 'SQ', '1', '00720012', undefined)
exports.NumberOfPriorsReferenced = new Element(7471124, 'NumberOfPriorsReferenced', 'US', '1', '00720014', undefined)
exports.ImageSetsSequence = new Element(7471136, 'ImageSetsSequence', 'SQ', '1', '00720020', undefined)
exports.ImageSetSelectorSequence = new Element(7471138, 'ImageSetSelectorSequence', 'SQ', '1', '00720022', undefined)
exports.ImageSetSelectorUsageFlag = new Element(7471140, 'ImageSetSelectorUsageFlag', 'CS', '1', '00720024', undefined)
exports.SelectorAttribute = new Element(7471142, 'SelectorAttribute', 'AT', '1', '00720026', undefined)
exports.SelectorValueNumber = new Element(7471144, 'SelectorValueNumber', 'US', '1', '00720028', undefined)
exports.TimeBasedImageSetsSequence = new Element(7471152, 'TimeBasedImageSetsSequence', 'SQ', '1', '00720030', undefined)
exports.ImageSetNumber = new Element(7471154, 'ImageSetNumber', 'US', '1', '00720032', undefined)
exports.ImageSetSelectorCategory = new Element(7471156, 'ImageSetSelectorCategory', 'CS', '1', '00720034', undefined)
exports.RelativeTime = new Element(7471160, 'RelativeTime', 'US', '2', '00720038', undefined)
exports.RelativeTimeUnits = new Element(7471162, 'RelativeTimeUnits', 'CS', '1', '0072003A', undefined)
exports.AbstractPriorValue = new Element(7471164, 'AbstractPriorValue', 'SS', '2', '0072003C', undefined)
exports.AbstractPriorCodeSequence = new Element(7471166, 'AbstractPriorCodeSequence', 'SQ', '1', '0072003E', undefined)
exports.ImageSetLabel = new Element(7471168, 'ImageSetLabel', 'LO', '1', '00720040', undefined)
exports.SelectorAttributeVR = new Element(7471184, 'SelectorAttributeVR', 'CS', '1', '00720050', undefined)
exports.SelectorSequencePointer = new Element(7471186, 'SelectorSequencePointer', 'AT', '1-n', '00720052', undefined)
exports.SelectorSequencePointerPrivateCreator = new Element(7471188, 'SelectorSequencePointerPrivateCreator', 'LO', '1-n', '00720054', undefined)
exports.SelectorAttributePrivateCreator = new Element(7471190, 'SelectorAttributePrivateCreator', 'LO', '1', '00720056', undefined)
exports.SelectorATValue = new Element(7471200, 'SelectorATValue', 'AT', '1-n', '00720060', undefined)
exports.SelectorCSValue = new Element(7471202, 'SelectorCSValue', 'CS', '1-n', '00720062', undefined)
exports.SelectorISValue = new Element(7471204, 'SelectorISValue', 'IS', '1-n', '00720064', undefined)
exports.SelectorLOValue = new Element(7471206, 'SelectorLOValue', 'LO', '1-n', '00720066', undefined)
exports.SelectorLTValue = new Element(7471208, 'SelectorLTValue', 'LT', '1', '00720068', undefined)
exports.SelectorPNValue = new Element(7471210, 'SelectorPNValue', 'PN', '1-n', '0072006A', undefined)
exports.SelectorSHValue = new Element(7471212, 'SelectorSHValue', 'SH', '1-n', '0072006C', undefined)
exports.SelectorSTValue = new Element(7471214, 'SelectorSTValue', 'ST', '1', '0072006E', undefined)
exports.SelectorUTValue = new Element(7471216, 'SelectorUTValue', 'UT', '1', '00720070', undefined)
exports.SelectorDSValue = new Element(7471218, 'SelectorDSValue', 'DS', '1-n', '00720072', undefined)
exports.SelectorFDValue = new Element(7471220, 'SelectorFDValue', 'FD', '1-n', '00720074', undefined)
exports.SelectorFLValue = new Element(7471222, 'SelectorFLValue', 'FL', '1-n', '00720076', undefined)
exports.SelectorULValue = new Element(7471224, 'SelectorULValue', 'UL', '1-n', '00720078', undefined)
exports.SelectorUSValue = new Element(7471226, 'SelectorUSValue', 'US', '1-n', '0072007A', undefined)
exports.SelectorSLValue = new Element(7471228, 'SelectorSLValue', 'SL', '1-n', '0072007C', undefined)
exports.SelectorSSValue = new Element(7471230, 'SelectorSSValue', 'SS', '1-n', '0072007E', undefined)
exports.SelectorCodeSequenceValue = new Element(7471232, 'SelectorCodeSequenceValue', 'SQ', '1', '00720080', undefined)
exports.NumberOfScreens = new Element(7471360, 'NumberOfScreens', 'US', '1', '00720100', undefined)
exports.NominalScreenDefinitionSequence = new Element(7471362, 'NominalScreenDefinitionSequence', 'SQ', '1', '00720102', undefined)
exports.NumberOfVerticalPixels = new Element(7471364, 'NumberOfVerticalPixels', 'US', '1', '00720104', undefined)
exports.NumberOfHorizontalPixels = new Element(7471366, 'NumberOfHorizontalPixels', 'US', '1', '00720106', undefined)
exports.DisplayEnvironmentSpatialPosition = new Element(7471368, 'DisplayEnvironmentSpatialPosition', 'FD', '4', '00720108', undefined)
exports.ScreenMinimumGrayscaleBitDepth = new Element(7471370, 'ScreenMinimumGrayscaleBitDepth', 'US', '1', '0072010A', undefined)
exports.ScreenMinimumColorBitDepth = new Element(7471372, 'ScreenMinimumColorBitDepth', 'US', '1', '0072010C', undefined)
exports.ApplicationMaximumRepaintTime = new Element(7471374, 'ApplicationMaximumRepaintTime', 'US', '1', '0072010E', undefined)
exports.DisplaySetsSequence = new Element(7471616, 'DisplaySetsSequence', 'SQ', '1', '00720200', undefined)
exports.DisplaySetNumber = new Element(7471618, 'DisplaySetNumber', 'US', '1', '00720202', undefined)
exports.DisplaySetLabel = new Element(7471619, 'DisplaySetLabel', 'LO', '1', '00720203', undefined)
exports.DisplaySetPresentationGroup = new Element(7471620, 'DisplaySetPresentationGroup', 'US', '1', '00720204', undefined)
exports.DisplaySetPresentationGroupDescription = new Element(7471622, 'DisplaySetPresentationGroupDescription', 'LO', '1', '00720206', undefined)
exports.PartialDataDisplayHandling = new Element(7471624, 'PartialDataDisplayHandling', 'CS', '1', '00720208', undefined)
exports.SynchronizedScrollingSequence = new Element(7471632, 'SynchronizedScrollingSequence', 'SQ', '1', '00720210', undefined)
exports.DisplaySetScrollingGroup = new Element(7471634, 'DisplaySetScrollingGroup', 'US', '2-n', '00720212', undefined)
exports.NavigationIndicatorSequence = new Element(7471636, 'NavigationIndicatorSequence', 'SQ', '1', '00720214', undefined)
exports.NavigationDisplaySet = new Element(7471638, 'NavigationDisplaySet', 'US', '1', '00720216', undefined)
exports.ReferenceDisplaySets = new Element(7471640, 'ReferenceDisplaySets', 'US', '1-n', '00720218', undefined)
exports.ImageBoxesSequence = new Element(7471872, 'ImageBoxesSequence', 'SQ', '1', '00720300', undefined)
exports.ImageBoxNumber = new Element(7471874, 'ImageBoxNumber', 'US', '1', '00720302', undefined)
exports.ImageBoxLayoutType = new Element(7471876, 'ImageBoxLayoutType', 'CS', '1', '00720304', undefined)
exports.ImageBoxTileHorizontalDimension = new Element(7471878, 'ImageBoxTileHorizontalDimension', 'US', '1', '00720306', undefined)
exports.ImageBoxTileVerticalDimension = new Element(7471880, 'ImageBoxTileVerticalDimension', 'US', '1', '00720308', undefined)
exports.ImageBoxScrollDirection = new Element(7471888, 'ImageBoxScrollDirection', 'CS', '1', '00720310', undefined)
exports.ImageBoxSmallScrollType = new Element(7471890, 'ImageBoxSmallScrollType', 'CS', '1', '00720312', undefined)
exports.ImageBoxSmallScrollAmount = new Element(7471892, 'ImageBoxSmallScrollAmount', 'US', '1', '00720314', undefined)
exports.ImageBoxLargeScrollType = new Element(7471894, 'ImageBoxLargeScrollType', 'CS', '1', '00720316', undefined)
exports.ImageBoxLargeScrollAmount = new Element(7471896, 'ImageBoxLargeScrollAmount', 'US', '1', '00720318', undefined)
exports.ImageBoxOverlapPriority = new Element(7471904, 'ImageBoxOverlapPriority', 'US', '1', '00720320', undefined)
exports.CineRelativeToRealTime = new Element(7471920, 'CineRelativeToRealTime', 'FD', '1', '00720330', undefined)
exports.FilterOperationsSequence = new Element(7472128, 'FilterOperationsSequence', 'SQ', '1', '00720400', undefined)
exports.FilterByCategory = new Element(7472130, 'FilterByCategory', 'CS', '1', '00720402', undefined)
exports.FilterByAttributePresence = new Element(7472132, 'FilterByAttributePresence', 'CS', '1', '00720404', undefined)
exports.FilterByOperator = new Element(7472134, 'FilterByOperator', 'CS', '1', '00720406', undefined)
exports.StructuredDisplayBackgroundCIELabValue = new Element(7472160, 'StructuredDisplayBackgroundCIELabValue', 'US', '3', '00720420', undefined)
exports.EmptyImageBoxCIELabValue = new Element(7472161, 'EmptyImageBoxCIELabValue', 'US', '3', '00720421', undefined)
exports.StructuredDisplayImageBoxSequence = new Element(7472162, 'StructuredDisplayImageBoxSequence', 'SQ', '1', '00720422', undefined)
exports.StructuredDisplayTextBoxSequence = new Element(7472164, 'StructuredDisplayTextBoxSequence', 'SQ', '1', '00720424', undefined)
exports.ReferencedFirstFrameSequence = new Element(7472167, 'ReferencedFirstFrameSequence', 'SQ', '1', '00720427', undefined)
exports.ImageBoxSynchronizationSequence = new Element(7472176, 'ImageBoxSynchronizationSequence', 'SQ', '1', '00720430', undefined)
exports.SynchronizedImageBoxList = new Element(7472178, 'SynchronizedImageBoxList', 'US', '2-n', '00720432', undefined)
exports.TypeOfSynchronization = new Element(7472180, 'TypeOfSynchronization', 'CS', '1', '00720434', undefined)
exports.BlendingOperationType = new Element(7472384, 'BlendingOperationType', 'CS', '1', '00720500', undefined)
exports.ReformattingOperationType = new Element(7472400, 'ReformattingOperationType', 'CS', '1', '00720510', undefined)
exports.ReformattingThickness = new Element(7472402, 'ReformattingThickness', 'FD', '1', '00720512', undefined)
exports.ReformattingInterval = new Element(7472404, 'ReformattingInterval', 'FD', '1', '00720514', undefined)
exports.ReformattingOperationInitialViewDirection = new Element(7472406, 'ReformattingOperationInitialViewDirection', 'CS', '1', '00720516', undefined)
exports.ThreeDRenderingType = new Element(7472416, 'ThreeDRenderingType', 'CS', '1-n', '00720520', undefined)
exports.SortingOperationsSequence = new Element(7472640, 'SortingOperationsSequence', 'SQ', '1', '00720600', undefined)
exports.SortByCategory = new Element(7472642, 'SortByCategory', 'CS', '1', '00720602', undefined)
exports.SortingDirection = new Element(7472644, 'SortingDirection', 'CS', '1', '00720604', undefined)
exports.DisplaySetPatientOrientation = new Element(7472896, 'DisplaySetPatientOrientation', 'CS', '2', '00720700', undefined)
exports.VOIType = new Element(7472898, 'VOIType', 'CS', '1', '00720702', undefined)
exports.PseudoColorType = new Element(7472900, 'PseudoColorType', 'CS', '1', '00720704', undefined)
exports.PseudoColorPaletteInstanceReferenceSequence = new Element(7472901, 'PseudoColorPaletteInstanceReferenceSequence', 'SQ', '1', '00720705', undefined)
exports.ShowGrayscaleInverted = new Element(7472902, 'ShowGrayscaleInverted', 'CS', '1', '00720706', undefined)
exports.ShowImageTrueSizeFlag = new Element(7472912, 'ShowImageTrueSizeFlag', 'CS', '1', '00720710', undefined)
exports.ShowGraphicAnnotationFlag = new Element(7472914, 'ShowGraphicAnnotationFlag', 'CS', '1', '00720712', undefined)
exports.ShowPatientDemographicsFlag = new Element(7472916, 'ShowPatientDemographicsFlag', 'CS', '1', '00720714', undefined)
exports.ShowAcquisitionTechniquesFlag = new Element(7472918, 'ShowAcquisitionTechniquesFlag', 'CS', '1', '00720716', undefined)
exports.DisplaySetHorizontalJustification = new Element(7472919, 'DisplaySetHorizontalJustification', 'CS', '1', '00720717', undefined)
exports.DisplaySetVerticalJustification = new Element(7472920, 'DisplaySetVerticalJustification', 'CS', '1', '00720718', undefined)
exports.ContinuationStartMeterset = new Element(7602464, 'ContinuationStartMeterset', 'FD', '1', '00740120', undefined)
exports.ContinuationEndMeterset = new Element(7602465, 'ContinuationEndMeterset', 'FD', '1', '00740121', undefined)
exports.ProcedureStepState = new Element(7606272, 'ProcedureStepState', 'CS', '1', '00741000', undefined)
exports.ProcedureStepProgressInformationSequence = new Element(7606274, 'ProcedureStepProgressInformationSequence', 'SQ', '1', '00741002', undefined)
exports.ProcedureStepProgress = new Element(7606276, 'ProcedureStepProgress', 'DS', '1', '00741004', undefined)
exports.ProcedureStepProgressDescription = new Element(7606278, 'ProcedureStepProgressDescription', 'ST', '1', '00741006', undefined)
exports.ProcedureStepCommunicationsURISequence = new Element(7606280, 'ProcedureStepCommunicationsURISequence', 'SQ', '1', '00741008', undefined)
exports.ContactURI = new Element(7606282, 'ContactURI', 'ST', '1', '0074100a', undefined)
exports.ContactDisplayName = new Element(7606284, 'ContactDisplayName', 'LO', '1', '0074100c', undefined)
exports.ProcedureStepDiscontinuationReasonCodeSequence = new Element(7606286, 'ProcedureStepDiscontinuationReasonCodeSequence', 'SQ', '1', '0074100e', undefined)
exports.BeamTaskSequence = new Element(7606304, 'BeamTaskSequence', 'SQ', '1', '00741020', undefined)
exports.BeamTaskType = new Element(7606306, 'BeamTaskType', 'CS', '1', '00741022', undefined)
exports.BeamOrderIndexTrial = new Element(7606308, 'BeamOrderIndexTrial', 'IS', '1', '00741024', true)
exports.AutosequenceFlag = new Element(7606309, 'AutosequenceFlag', 'CS', '1', '00741025', undefined)
exports.TableTopVerticalAdjustedPosition = new Element(7606310, 'TableTopVerticalAdjustedPosition', 'FD', '1', '00741026', undefined)
exports.TableTopLongitudinalAdjustedPosition = new Element(7606311, 'TableTopLongitudinalAdjustedPosition', 'FD', '1', '00741027', undefined)
exports.TableTopLateralAdjustedPosition = new Element(7606312, 'TableTopLateralAdjustedPosition', 'FD', '1', '00741028', undefined)
exports.PatientSupportAdjustedAngle = new Element(7606314, 'PatientSupportAdjustedAngle', 'FD', '1', '0074102A', undefined)
exports.TableTopEccentricAdjustedAngle = new Element(7606315, 'TableTopEccentricAdjustedAngle', 'FD', '1', '0074102B', undefined)
exports.TableTopPitchAdjustedAngle = new Element(7606316, 'TableTopPitchAdjustedAngle', 'FD', '1', '0074102C', undefined)
exports.TableTopRollAdjustedAngle = new Element(7606317, 'TableTopRollAdjustedAngle', 'FD', '1', '0074102D', undefined)
exports.DeliveryVerificationImageSequence = new Element(7606320, 'DeliveryVerificationImageSequence', 'SQ', '1', '00741030', undefined)
exports.VerificationImageTiming = new Element(7606322, 'VerificationImageTiming', 'CS', '1', '00741032', undefined)
exports.DoubleExposureFlag = new Element(7606324, 'DoubleExposureFlag', 'CS', '1', '00741034', undefined)
exports.DoubleExposureOrdering = new Element(7606326, 'DoubleExposureOrdering', 'CS', '1', '00741036', undefined)
exports.DoubleExposureMetersetTrial = new Element(7606328, 'DoubleExposureMetersetTrial', 'DS', '1', '00741038', true)
exports.DoubleExposureFieldDeltaTrial = new Element(7606330, 'DoubleExposureFieldDeltaTrial', 'DS', '4', '0074103A', true)
exports.RelatedReferenceRTImageSequence = new Element(7606336, 'RelatedReferenceRTImageSequence', 'SQ', '1', '00741040', undefined)
exports.GeneralMachineVerificationSequence = new Element(7606338, 'GeneralMachineVerificationSequence', 'SQ', '1', '00741042', undefined)
exports.ConventionalMachineVerificationSequence = new Element(7606340, 'ConventionalMachineVerificationSequence', 'SQ', '1', '00741044', undefined)
exports.IonMachineVerificationSequence = new Element(7606342, 'IonMachineVerificationSequence', 'SQ', '1', '00741046', undefined)
exports.FailedAttributesSequence = new Element(7606344, 'FailedAttributesSequence', 'SQ', '1', '00741048', undefined)
exports.OverriddenAttributesSequence = new Element(7606346, 'OverriddenAttributesSequence', 'SQ', '1', '0074104A', undefined)
exports.ConventionalControlPointVerificationSequence = new Element(7606348, 'ConventionalControlPointVerificationSequence', 'SQ', '1', '0074104C', undefined)
exports.IonControlPointVerificationSequence = new Element(7606350, 'IonControlPointVerificationSequence', 'SQ', '1', '0074104E', undefined)
exports.AttributeOccurrenceSequence = new Element(7606352, 'AttributeOccurrenceSequence', 'SQ', '1', '00741050', undefined)
exports.AttributeOccurrencePointer = new Element(7606354, 'AttributeOccurrencePointer', 'AT', '1', '00741052', undefined)
exports.AttributeItemSelector = new Element(7606356, 'AttributeItemSelector', 'UL', '1', '00741054', undefined)
exports.AttributeOccurrencePrivateCreator = new Element(7606358, 'AttributeOccurrencePrivateCreator', 'LO', '1', '00741056', undefined)
exports.SelectorSequencePointerItems = new Element(7606359, 'SelectorSequencePointerItems', 'IS', '1-n', '00741057', undefined)
exports.ScheduledProcedureStepPriority = new Element(7606784, 'ScheduledProcedureStepPriority', 'CS', '1', '00741200', undefined)
exports.WorklistLabel = new Element(7606786, 'WorklistLabel', 'LO', '1', '00741202', undefined)
exports.ProcedureStepLabel = new Element(7606788, 'ProcedureStepLabel', 'LO', '1', '00741204', undefined)
exports.ScheduledProcessingParametersSequence = new Element(7606800, 'ScheduledProcessingParametersSequence', 'SQ', '1', '00741210', undefined)
exports.PerformedProcessingParametersSequence = new Element(7606802, 'PerformedProcessingParametersSequence', 'SQ', '1', '00741212', undefined)
exports.UnifiedProcedureStepPerformedProcedureSequence = new Element(7606806, 'UnifiedProcedureStepPerformedProcedureSequence', 'SQ', '1', '00741216', undefined)
exports.RelatedProcedureStepSequence = new Element(7606816, 'RelatedProcedureStepSequence', 'SQ', '1', '00741220', true)
exports.ProcedureStepRelationshipType = new Element(7606818, 'ProcedureStepRelationshipType', 'LO', '1', '00741222', true)
exports.ReplacedProcedureStepSequence = new Element(7606820, 'ReplacedProcedureStepSequence', 'SQ', '1', '00741224', undefined)
exports.DeletionLock = new Element(7606832, 'DeletionLock', 'LO', '1', '00741230', undefined)
exports.ReceivingAE = new Element(7606836, 'ReceivingAE', 'AE', '1', '00741234', undefined)
exports.RequestingAE = new Element(7606838, 'RequestingAE', 'AE', '1', '00741236', undefined)
exports.ReasonForCancellation = new Element(7606840, 'ReasonForCancellation', 'LT', '1', '00741238', undefined)
exports.SCPStatus = new Element(7606850, 'SCPStatus', 'CS', '1', '00741242', undefined)
exports.SubscriptionListStatus = new Element(7606852, 'SubscriptionListStatus', 'CS', '1', '00741244', undefined)
exports.UnifiedProcedureStepListStatus = new Element(7606854, 'UnifiedProcedureStepListStatus', 'CS', '1', '00741246', undefined)
exports.BeamOrderIndex = new Element(7607076, 'BeamOrderIndex', 'UL', '1', '00741324', undefined)
exports.DoubleExposureMeterset = new Element(7607096, 'DoubleExposureMeterset', 'FD', '1', '00741338', undefined)
exports.DoubleExposureFieldDelta = new Element(7607098, 'DoubleExposureFieldDelta', 'FD', '4', '0074133A', undefined)
exports.ImplantAssemblyTemplateName = new Element(7733249, 'ImplantAssemblyTemplateName', 'LO', '1', '00760001', undefined)
exports.ImplantAssemblyTemplateIssuer = new Element(7733251, 'ImplantAssemblyTemplateIssuer', 'LO', '1', '00760003', undefined)
exports.ImplantAssemblyTemplateVersion = new Element(7733254, 'ImplantAssemblyTemplateVersion', 'LO', '1', '00760006', undefined)
exports.ReplacedImplantAssemblyTemplateSequence = new Element(7733256, 'ReplacedImplantAssemblyTemplateSequence', 'SQ', '1', '00760008', undefined)
exports.ImplantAssemblyTemplateType = new Element(7733258, 'ImplantAssemblyTemplateType', 'CS', '1', '0076000A', undefined)
exports.OriginalImplantAssemblyTemplateSequence = new Element(7733260, 'OriginalImplantAssemblyTemplateSequence', 'SQ', '1', '0076000C', undefined)
exports.DerivationImplantAssemblyTemplateSequence = new Element(7733262, 'DerivationImplantAssemblyTemplateSequence', 'SQ', '1', '0076000E', undefined)
exports.ImplantAssemblyTemplateTargetAnatomySequence = new Element(7733264, 'ImplantAssemblyTemplateTargetAnatomySequence', 'SQ', '1', '00760010', undefined)
exports.ProcedureTypeCodeSequence = new Element(7733280, 'ProcedureTypeCodeSequence', 'SQ', '1', '00760020', undefined)
exports.SurgicalTechnique = new Element(7733296, 'SurgicalTechnique', 'LO', '1', '00760030', undefined)
exports.ComponentTypesSequence = new Element(7733298, 'ComponentTypesSequence', 'SQ', '1', '00760032', undefined)
exports.ComponentTypeCodeSequence = new Element(7733300, 'ComponentTypeCodeSequence', 'CS', '1', '00760034', undefined)
exports.ExclusiveComponentType = new Element(7733302, 'ExclusiveComponentType', 'CS', '1', '00760036', undefined)
exports.MandatoryComponentType = new Element(7733304, 'MandatoryComponentType', 'CS', '1', '00760038', undefined)
exports.ComponentSequence = new Element(7733312, 'ComponentSequence', 'SQ', '1', '00760040', undefined)
exports.ComponentID = new Element(7733333, 'ComponentID', 'US', '1', '00760055', undefined)
exports.ComponentAssemblySequence = new Element(7733344, 'ComponentAssemblySequence', 'SQ', '1', '00760060', undefined)
exports.Component1ReferencedID = new Element(7733360, 'Component1ReferencedID', 'US', '1', '00760070', undefined)
exports.Component1ReferencedMatingFeatureSetID = new Element(7733376, 'Component1ReferencedMatingFeatureSetID', 'US', '1', '00760080', undefined)
exports.Component1ReferencedMatingFeatureID = new Element(7733392, 'Component1ReferencedMatingFeatureID', 'US', '1', '00760090', undefined)
exports.Component2ReferencedID = new Element(7733408, 'Component2ReferencedID', 'US', '1', '007600A0', undefined)
exports.Component2ReferencedMatingFeatureSetID = new Element(7733424, 'Component2ReferencedMatingFeatureSetID', 'US', '1', '007600B0', undefined)
exports.Component2ReferencedMatingFeatureID = new Element(7733440, 'Component2ReferencedMatingFeatureID', 'US', '1', '007600C0', undefined)
exports.ImplantTemplateGroupName = new Element(7864321, 'ImplantTemplateGroupName', 'LO', '1', '00780001', undefined)
exports.ImplantTemplateGroupDescription = new Element(7864336, 'ImplantTemplateGroupDescription', 'ST', '1', '00780010', undefined)
exports.ImplantTemplateGroupIssuer = new Element(7864352, 'ImplantTemplateGroupIssuer', 'LO', '1', '00780020', undefined)
exports.ImplantTemplateGroupVersion = new Element(7864356, 'ImplantTemplateGroupVersion', 'LO', '1', '00780024', undefined)
exports.ReplacedImplantTemplateGroupSequence = new Element(7864358, 'ReplacedImplantTemplateGroupSequence', 'SQ', '1', '00780026', undefined)
exports.ImplantTemplateGroupTargetAnatomySequence = new Element(7864360, 'ImplantTemplateGroupTargetAnatomySequence', 'SQ', '1', '00780028', undefined)
exports.ImplantTemplateGroupMembersSequence = new Element(7864362, 'ImplantTemplateGroupMembersSequence', 'SQ', '1', '0078002A', undefined)
exports.ImplantTemplateGroupMemberID = new Element(7864366, 'ImplantTemplateGroupMemberID', 'US', '1', '0078002E', undefined)
exports.ThreeDImplantTemplateGroupMemberMatchingPoint = new Element(7864400, 'ThreeDImplantTemplateGroupMemberMatchingPoint', 'FD', '3', '00780050', undefined)
exports.ThreeDImplantTemplateGroupMemberMatchingAxes = new Element(7864416, 'ThreeDImplantTemplateGroupMemberMatchingAxes', 'FD', '9', '00780060', undefined)
exports.ImplantTemplateGroupMemberMatching2DCoordinatesSequence = new Element(7864432, 'ImplantTemplateGroupMemberMatching2DCoordinatesSequence', 'SQ', '1', '00780070', undefined)
exports.TwoDImplantTemplateGroupMemberMatchingPoint = new Element(7864464, 'TwoDImplantTemplateGroupMemberMatchingPoint', 'FD', '2', '00780090', undefined)
exports.TwoDImplantTemplateGroupMemberMatchingAxes = new Element(7864480, 'TwoDImplantTemplateGroupMemberMatchingAxes', 'FD', '4', '007800A0', undefined)
exports.ImplantTemplateGroupVariationDimensionSequence = new Element(7864496, 'ImplantTemplateGroupVariationDimensionSequence', 'SQ', '1', '007800B0', undefined)
exports.ImplantTemplateGroupVariationDimensionName = new Element(7864498, 'ImplantTemplateGroupVariationDimensionName', 'LO', '1', '007800B2', undefined)
exports.ImplantTemplateGroupVariationDimensionRankSequence = new Element(7864500, 'ImplantTemplateGroupVariationDimensionRankSequence', 'SQ', '1', '007800B4', undefined)
exports.ReferencedImplantTemplateGroupMemberID = new Element(7864502, 'ReferencedImplantTemplateGroupMemberID', 'US', '1', '007800B6', undefined)
exports.ImplantTemplateGroupVariationDimensionRank = new Element(7864504, 'ImplantTemplateGroupVariationDimensionRank', 'US', '1', '007800B8', undefined)
exports.SurfaceScanAcquisitionTypeCodeSequence = new Element(8388609, 'SurfaceScanAcquisitionTypeCodeSequence', 'SQ', '1', '00800001', undefined)
exports.SurfaceScanModeCodeSequence = new Element(8388610, 'SurfaceScanModeCodeSequence', 'SQ', '1', '00800002', undefined)
exports.RegistrationMethodCodeSequence = new Element(8388611, 'RegistrationMethodCodeSequence', 'SQ', '1', '00800003', undefined)
exports.ShotDurationTime = new Element(8388612, 'ShotDurationTime', 'FD', '1', '00800004', undefined)
exports.ShotOffsetTime = new Element(8388613, 'ShotOffsetTime', 'FD', '1', '00800005', undefined)
exports.SurfacePointPresentationValueData = new Element(8388614, 'SurfacePointPresentationValueData', 'US', '1-n', '00800006', undefined)
exports.SurfacePointColorCIELabValueData = new Element(8388615, 'SurfacePointColorCIELabValueData', 'US', '3-3n', '00800007', undefined)
exports.UVMappingSequence = new Element(8388616, 'UVMappingSequence', 'SQ', '1', '00800008', undefined)
exports.TextureLabel = new Element(8388617, 'TextureLabel', 'SH', '1', '00800009', undefined)
exports.UValueData = new Element(8388624, 'UValueData', 'OF', '1-n', '00800010', undefined)
exports.VValueData = new Element(8388625, 'VValueData', 'OF', '1-n', '00800011', undefined)
exports.ReferencedTextureSequence = new Element(8388626, 'ReferencedTextureSequence', 'SQ', '1', '00800012', undefined)
exports.ReferencedSurfaceDataSequence = new Element(8388627, 'ReferencedSurfaceDataSequence', 'SQ', '1', '00800013', undefined)
exports.StorageMediaFileSetID = new Element(8913200, 'StorageMediaFileSetID', 'SH', '1', '00880130', undefined)
exports.StorageMediaFileSetUID = new Element(8913216, 'StorageMediaFileSetUID', 'UI', '1', '00880140', undefined)
exports.IconImageSequence = new Element(8913408, 'IconImageSequence', 'SQ', '1', '00880200', undefined)
exports.TopicTitle = new Element(8915204, 'TopicTitle', 'LO', '1', '00880904', true)
exports.TopicSubject = new Element(8915206, 'TopicSubject', 'ST', '1', '00880906', true)
exports.TopicAuthor = new Element(8915216, 'TopicAuthor', 'LO', '1', '00880910', true)
exports.TopicKeywords = new Element(8915218, 'TopicKeywords', 'LO', '1-32', '00880912', true)
exports.SOPInstanceStatus = new Element(16778256, 'SOPInstanceStatus', 'CS', '1', '01000410', undefined)
exports.SOPAuthorizationDateTime = new Element(16778272, 'SOPAuthorizationDateTime', 'DT', '1', '01000420', undefined)
exports.SOPAuthorizationComment = new Element(16778276, 'SOPAuthorizationComment', 'LT', '1', '01000424', undefined)
exports.AuthorizationEquipmentCertificationNumber = new Element(16778278, 'AuthorizationEquipmentCertificationNumber', 'LO', '1', '01000426', undefined)
exports.MACIDNumber = new Element(67108869, 'MACIDNumber', 'US', '1', '04000005', undefined)
exports.MACCalculationTransferSyntaxUID = new Element(67108880, 'MACCalculationTransferSyntaxUID', 'UI', '1', '04000010', undefined)
exports.MACAlgorithm = new Element(67108885, 'MACAlgorithm', 'CS', '1', '04000015', undefined)
exports.DataElementsSigned = new Element(67108896, 'DataElementsSigned', 'AT', '1-n', '04000020', undefined)
exports.DigitalSignatureUID = new Element(67109120, 'DigitalSignatureUID', 'UI', '1', '04000100', undefined)
exports.DigitalSignatureDateTime = new Element(67109125, 'DigitalSignatureDateTime', 'DT', '1', '04000105', undefined)
exports.CertificateType = new Element(67109136, 'CertificateType', 'CS', '1', '04000110', undefined)
exports.CertificateOfSigner = new Element(67109141, 'CertificateOfSigner', 'OB', '1', '04000115', undefined)
exports.Signature = new Element(67109152, 'Signature', 'OB', '1', '04000120', undefined)
exports.CertifiedTimestampType = new Element(67109637, 'CertifiedTimestampType', 'CS', '1', '04000305', undefined)
exports.CertifiedTimestamp = new Element(67109648, 'CertifiedTimestamp', 'OB', '1', '04000310', undefined)
exports.DigitalSignaturePurposeCodeSequence = new Element(67109889, 'DigitalSignaturePurposeCodeSequence', 'SQ', '1', '04000401', undefined)
exports.ReferencedDigitalSignatureSequence = new Element(67109890, 'ReferencedDigitalSignatureSequence', 'SQ', '1', '04000402', undefined)
exports.ReferencedSOPInstanceMACSequence = new Element(67109891, 'ReferencedSOPInstanceMACSequence', 'SQ', '1', '04000403', undefined)
exports.MAC = new Element(67109892, 'MAC', 'OB', '1', '04000404', undefined)
exports.EncryptedAttributesSequence = new Element(67110144, 'EncryptedAttributesSequence', 'SQ', '1', '04000500', undefined)
exports.EncryptedContentTransferSyntaxUID = new Element(67110160, 'EncryptedContentTransferSyntaxUID', 'UI', '1', '04000510', undefined)
exports.EncryptedContent = new Element(67110176, 'EncryptedContent', 'OB', '1', '04000520', undefined)
exports.ModifiedAttributesSequence = new Element(67110224, 'ModifiedAttributesSequence', 'SQ', '1', '04000550', undefined)
exports.OriginalAttributesSequence = new Element(67110241, 'OriginalAttributesSequence', 'SQ', '1', '04000561', undefined)
exports.AttributeModificationDateTime = new Element(67110242, 'AttributeModificationDateTime', 'DT', '1', '04000562', undefined)
exports.ModifyingSystem = new Element(67110243, 'ModifyingSystem', 'LO', '1', '04000563', undefined)
exports.SourceOfPreviousValues = new Element(67110244, 'SourceOfPreviousValues', 'LO', '1', '04000564', undefined)
exports.ReasonForTheAttributeModification = new Element(67110245, 'ReasonForTheAttributeModification', 'CS', '1', '04000565', undefined)
exports.EscapeTriplet = new Element(268435456, 'EscapeTriplet', 'US', '3', '1000xxx0', true)
exports.RunLengthTriplet = new Element(268435457, 'RunLengthTriplet', 'US', '3', '1000xxx1', true)
exports.HuffmanTableSize = new Element(268435458, 'HuffmanTableSize', 'US', '1', '1000xxx2', true)
exports.HuffmanTableTriplet = new Element(268435459, 'HuffmanTableTriplet', 'US', '3', '1000xxx3', true)
exports.ShiftTableSize = new Element(268435460, 'ShiftTableSize', 'US', '1', '1000xxx4', true)
exports.ShiftTableTriplet = new Element(268435461, 'ShiftTableTriplet', 'US', '3', '1000xxx5', true)
exports.ZonalMap = new Element(269484032, 'ZonalMap', 'US', '1-n', '1010xxxx', true)
exports.NumberOfCopies = new Element(536870928, 'NumberOfCopies', 'IS', '1', '20000010', undefined)
exports.PrinterConfigurationSequence = new Element(536870942, 'PrinterConfigurationSequence', 'SQ', '1', '2000001E', undefined)
exports.PrintPriority = new Element(536870944, 'PrintPriority', 'CS', '1', '20000020', undefined)
exports.MediumType = new Element(536870960, 'MediumType', 'CS', '1', '20000030', undefined)
exports.FilmDestination = new Element(536870976, 'FilmDestination', 'CS', '1', '20000040', undefined)
exports.FilmSessionLabel = new Element(536870992, 'FilmSessionLabel', 'LO', '1', '20000050', undefined)
exports.MemoryAllocation = new Element(536871008, 'MemoryAllocation', 'IS', '1', '20000060', undefined)
exports.MaximumMemoryAllocation = new Element(536871009, 'MaximumMemoryAllocation', 'IS', '1', '20000061', undefined)
exports.ColorImagePrintingFlag = new Element(536871010, 'ColorImagePrintingFlag', 'CS', '1', '20000062', true)
exports.CollationFlag = new Element(536871011, 'CollationFlag', 'CS', '1', '20000063', true)
exports.AnnotationFlag = new Element(536871013, 'AnnotationFlag', 'CS', '1', '20000065', true)
exports.ImageOverlayFlag = new Element(536871015, 'ImageOverlayFlag', 'CS', '1', '20000067', true)
exports.PresentationLUTFlag = new Element(536871017, 'PresentationLUTFlag', 'CS', '1', '20000069', true)
exports.ImageBoxPresentationLUTFlag = new Element(536871018, 'ImageBoxPresentationLUTFlag', 'CS', '1', '2000006A', true)
exports.MemoryBitDepth = new Element(536871072, 'MemoryBitDepth', 'US', '1', '200000A0', undefined)
exports.PrintingBitDepth = new Element(536871073, 'PrintingBitDepth', 'US', '1', '200000A1', undefined)
exports.MediaInstalledSequence = new Element(536871074, 'MediaInstalledSequence', 'SQ', '1', '200000A2', undefined)
exports.OtherMediaAvailableSequence = new Element(536871076, 'OtherMediaAvailableSequence', 'SQ', '1', '200000A4', undefined)
exports.SupportedImageDisplayFormatsSequence = new Element(536871080, 'SupportedImageDisplayFormatsSequence', 'SQ', '1', '200000A8', undefined)
exports.ReferencedFilmBoxSequence = new Element(536872192, 'ReferencedFilmBoxSequence', 'SQ', '1', '20000500', undefined)
exports.ReferencedStoredPrintSequence = new Element(536872208, 'ReferencedStoredPrintSequence', 'SQ', '1', '20000510', true)
exports.ImageDisplayFormat = new Element(537919504, 'ImageDisplayFormat', 'ST', '1', '20100010', undefined)
exports.AnnotationDisplayFormatID = new Element(537919536, 'AnnotationDisplayFormatID', 'CS', '1', '20100030', undefined)
exports.FilmOrientation = new Element(537919552, 'FilmOrientation', 'CS', '1', '20100040', undefined)
exports.FilmSizeID = new Element(537919568, 'FilmSizeID', 'CS', '1', '20100050', undefined)
exports.PrinterResolutionID = new Element(537919570, 'PrinterResolutionID', 'CS', '1', '20100052', undefined)
exports.DefaultPrinterResolutionID = new Element(537919572, 'DefaultPrinterResolutionID', 'CS', '1', '20100054', undefined)
exports.MagnificationType = new Element(537919584, 'MagnificationType', 'CS', '1', '20100060', undefined)
exports.SmoothingType = new Element(537919616, 'SmoothingType', 'CS', '1', '20100080', undefined)
exports.DefaultMagnificationType = new Element(537919654, 'DefaultMagnificationType', 'CS', '1', '201000A6', undefined)
exports.OtherMagnificationTypesAvailable = new Element(537919655, 'OtherMagnificationTypesAvailable', 'CS', '1-n', '201000A7', undefined)
exports.DefaultSmoothingType = new Element(537919656, 'DefaultSmoothingType', 'CS', '1', '201000A8', undefined)
exports.OtherSmoothingTypesAvailable = new Element(537919657, 'OtherSmoothingTypesAvailable', 'CS', '1-n', '201000A9', undefined)
exports.BorderDensity = new Element(537919744, 'BorderDensity', 'CS', '1', '20100100', undefined)
exports.EmptyImageDensity = new Element(537919760, 'EmptyImageDensity', 'CS', '1', '20100110', undefined)
exports.MinDensity = new Element(537919776, 'MinDensity', 'US', '1', '20100120', undefined)
exports.MaxDensity = new Element(537919792, 'MaxDensity', 'US', '1', '20100130', undefined)
exports.Trim = new Element(537919808, 'Trim', 'CS', '1', '20100140', undefined)
exports.ConfigurationInformation = new Element(537919824, 'ConfigurationInformation', 'ST', '1', '20100150', undefined)
exports.ConfigurationInformationDescription = new Element(537919826, 'ConfigurationInformationDescription', 'LT', '1', '20100152', undefined)
exports.MaximumCollatedFilms = new Element(537919828, 'MaximumCollatedFilms', 'IS', '1', '20100154', undefined)
exports.Illumination = new Element(537919838, 'Illumination', 'US', '1', '2010015E', undefined)
exports.ReflectedAmbientLight = new Element(537919840, 'ReflectedAmbientLight', 'US', '1', '20100160', undefined)
exports.PrinterPixelSpacing = new Element(537920374, 'PrinterPixelSpacing', 'DS', '2', '20100376', undefined)
exports.ReferencedFilmSessionSequence = new Element(537920768, 'ReferencedFilmSessionSequence', 'SQ', '1', '20100500', undefined)
exports.ReferencedImageBoxSequence = new Element(537920784, 'ReferencedImageBoxSequence', 'SQ', '1', '20100510', undefined)
exports.ReferencedBasicAnnotationBoxSequence = new Element(537920800, 'ReferencedBasicAnnotationBoxSequence', 'SQ', '1', '20100520', undefined)
exports.ImageBoxPosition = new Element(538968080, 'ImageBoxPosition', 'US', '1', '20200010', undefined)
exports.Polarity = new Element(538968096, 'Polarity', 'CS', '1', '20200020', undefined)
exports.RequestedImageSize = new Element(538968112, 'RequestedImageSize', 'DS', '1', '20200030', undefined)
exports.RequestedDecimateCropBehavior = new Element(538968128, 'RequestedDecimateCropBehavior', 'CS', '1', '20200040', undefined)
exports.RequestedResolutionID = new Element(538968144, 'RequestedResolutionID', 'CS', '1', '20200050', undefined)
exports.RequestedImageSizeFlag = new Element(538968224, 'RequestedImageSizeFlag', 'CS', '1', '202000A0', undefined)
exports.DecimateCropResult = new Element(538968226, 'DecimateCropResult', 'CS', '1', '202000A2', undefined)
exports.BasicGrayscaleImageSequence = new Element(538968336, 'BasicGrayscaleImageSequence', 'SQ', '1', '20200110', undefined)
exports.BasicColorImageSequence = new Element(538968337, 'BasicColorImageSequence', 'SQ', '1', '20200111', undefined)
exports.ReferencedImageOverlayBoxSequence = new Element(538968368, 'ReferencedImageOverlayBoxSequence', 'SQ', '1', '20200130', true)
exports.ReferencedVOILUTBoxSequence = new Element(538968384, 'ReferencedVOILUTBoxSequence', 'SQ', '1', '20200140', true)
exports.AnnotationPosition = new Element(540016656, 'AnnotationPosition', 'US', '1', '20300010', undefined)
exports.TextString = new Element(540016672, 'TextString', 'LO', '1', '20300020', undefined)
exports.ReferencedOverlayPlaneSequence = new Element(541065232, 'ReferencedOverlayPlaneSequence', 'SQ', '1', '20400010', true)
exports.ReferencedOverlayPlaneGroups = new Element(541065233, 'ReferencedOverlayPlaneGroups', 'US', '1-99', '20400011', true)
exports.OverlayPixelDataSequence = new Element(541065248, 'OverlayPixelDataSequence', 'SQ', '1', '20400020', true)
exports.OverlayMagnificationType = new Element(541065312, 'OverlayMagnificationType', 'CS', '1', '20400060', true)
exports.OverlaySmoothingType = new Element(541065328, 'OverlaySmoothingType', 'CS', '1', '20400070', true)
exports.OverlayOrImageMagnification = new Element(541065330, 'OverlayOrImageMagnification', 'CS', '1', '20400072', true)
exports.MagnifyToNumberOfColumns = new Element(541065332, 'MagnifyToNumberOfColumns', 'US', '1', '20400074', true)
exports.OverlayForegroundDensity = new Element(541065344, 'OverlayForegroundDensity', 'CS', '1', '20400080', true)
exports.OverlayBackgroundDensity = new Element(541065346, 'OverlayBackgroundDensity', 'CS', '1', '20400082', true)
exports.OverlayMode = new Element(541065360, 'OverlayMode', 'CS', '1', '20400090', true)
exports.ThresholdDensity = new Element(541065472, 'ThresholdDensity', 'CS', '1', '20400100', true)
exports.ReferencedImageBoxSequenceRetired = new Element(541066496, 'ReferencedImageBoxSequenceRetired', 'SQ', '1', '20400500', true)
exports.PresentationLUTSequence = new Element(542113808, 'PresentationLUTSequence', 'SQ', '1', '20500010', undefined)
exports.PresentationLUTShape = new Element(542113824, 'PresentationLUTShape', 'CS', '1', '20500020', undefined)
exports.ReferencedPresentationLUTSequence = new Element(542115072, 'ReferencedPresentationLUTSequence', 'SQ', '1', '20500500', undefined)
exports.PrintJobID = new Element(553648144, 'PrintJobID', 'SH', '1', '21000010', true)
exports.ExecutionStatus = new Element(553648160, 'ExecutionStatus', 'CS', '1', '21000020', undefined)
exports.ExecutionStatusInfo = new Element(553648176, 'ExecutionStatusInfo', 'CS', '1', '21000030', undefined)
exports.CreationDate = new Element(553648192, 'CreationDate', 'DA', '1', '21000040', undefined)
exports.CreationTime = new Element(553648208, 'CreationTime', 'TM', '1', '21000050', undefined)
exports.Originator = new Element(553648240, 'Originator', 'AE', '1', '21000070', undefined)
exports.DestinationAE = new Element(553648448, 'DestinationAE', 'AE', '1', '21000140', true)
exports.OwnerID = new Element(553648480, 'OwnerID', 'SH', '1', '21000160', undefined)
exports.NumberOfFilms = new Element(553648496, 'NumberOfFilms', 'IS', '1', '21000170', undefined)
exports.ReferencedPrintJobSequencePullStoredPrint = new Element(553649408, 'ReferencedPrintJobSequencePullStoredPrint', 'SQ', '1', '21000500', true)
exports.PrinterStatus = new Element(554696720, 'PrinterStatus', 'CS', '1', '21100010', undefined)
exports.PrinterStatusInfo = new Element(554696736, 'PrinterStatusInfo', 'CS', '1', '21100020', undefined)
exports.PrinterName = new Element(554696752, 'PrinterName', 'LO', '1', '21100030', undefined)
exports.PrintQueueID = new Element(554696857, 'PrintQueueID', 'SH', '1', '21100099', true)
exports.QueueStatus = new Element(555745296, 'QueueStatus', 'CS', '1', '21200010', true)
exports.PrintJobDescriptionSequence = new Element(555745360, 'PrintJobDescriptionSequence', 'SQ', '1', '21200050', true)
exports.ReferencedPrintJobSequence = new Element(555745392, 'ReferencedPrintJobSequence', 'SQ', '1', '21200070', true)
exports.PrintManagementCapabilitiesSequence = new Element(556793872, 'PrintManagementCapabilitiesSequence', 'SQ', '1', '21300010', true)
exports.PrinterCharacteristicsSequence = new Element(556793877, 'PrinterCharacteristicsSequence', 'SQ', '1', '21300015', true)
exports.FilmBoxContentSequence = new Element(556793904, 'FilmBoxContentSequence', 'SQ', '1', '21300030', true)
exports.ImageBoxContentSequence = new Element(556793920, 'ImageBoxContentSequence', 'SQ', '1', '21300040', true)
exports.AnnotationContentSequence = new Element(556793936, 'AnnotationContentSequence', 'SQ', '1', '21300050', true)
exports.ImageOverlayBoxContentSequence = new Element(556793952, 'ImageOverlayBoxContentSequence', 'SQ', '1', '21300060', true)
exports.PresentationLUTContentSequence = new Element(556793984, 'PresentationLUTContentSequence', 'SQ', '1', '21300080', true)
exports.ProposedStudySequence = new Element(556794016, 'ProposedStudySequence', 'SQ', '1', '213000A0', true)
exports.OriginalImageSequence = new Element(556794048, 'OriginalImageSequence', 'SQ', '1', '213000C0', true)
exports.LabelUsingInformationExtractedFromInstances = new Element(570425345, 'LabelUsingInformationExtractedFromInstances', 'CS', '1', '22000001', undefined)
exports.LabelText = new Element(570425346, 'LabelText', 'UT', '1', '22000002', undefined)
exports.LabelStyleSelection = new Element(570425347, 'LabelStyleSelection', 'CS', '1', '22000003', undefined)
exports.MediaDisposition = new Element(570425348, 'MediaDisposition', 'LT', '1', '22000004', undefined)
exports.BarcodeValue = new Element(570425349, 'BarcodeValue', 'LT', '1', '22000005', undefined)
exports.BarcodeSymbology = new Element(570425350, 'BarcodeSymbology', 'CS', '1', '22000006', undefined)
exports.AllowMediaSplitting = new Element(570425351, 'AllowMediaSplitting', 'CS', '1', '22000007', undefined)
exports.IncludeNonDICOMObjects = new Element(570425352, 'IncludeNonDICOMObjects', 'CS', '1', '22000008', undefined)
exports.IncludeDisplayApplication = new Element(570425353, 'IncludeDisplayApplication', 'CS', '1', '22000009', undefined)
exports.PreserveCompositeInstancesAfterMediaCreation = new Element(570425354, 'PreserveCompositeInstancesAfterMediaCreation', 'CS', '1', '2200000A', undefined)
exports.TotalNumberOfPiecesOfMediaCreated = new Element(570425355, 'TotalNumberOfPiecesOfMediaCreated', 'US', '1', '2200000B', undefined)
exports.RequestedMediaApplicationProfile = new Element(570425356, 'RequestedMediaApplicationProfile', 'LO', '1', '2200000C', undefined)
exports.ReferencedStorageMediaSequence = new Element(570425357, 'ReferencedStorageMediaSequence', 'SQ', '1', '2200000D', undefined)
exports.FailureAttributes = new Element(570425358, 'FailureAttributes', 'AT', '1-n', '2200000E', undefined)
exports.AllowLossyCompression = new Element(570425359, 'AllowLossyCompression', 'CS', '1', '2200000F', undefined)
exports.RequestPriority = new Element(570425376, 'RequestPriority', 'CS', '1', '22000020', undefined)
exports.RTImageLabel = new Element(805437442, 'RTImageLabel', 'SH', '1', '30020002', undefined)
exports.RTImageName = new Element(805437443, 'RTImageName', 'LO', '1', '30020003', undefined)
exports.RTImageDescription = new Element(805437444, 'RTImageDescription', 'ST', '1', '30020004', undefined)
exports.ReportedValuesOrigin = new Element(805437450, 'ReportedValuesOrigin', 'CS', '1', '3002000A', undefined)
exports.RTImagePlane = new Element(805437452, 'RTImagePlane', 'CS', '1', '3002000C', undefined)
exports.XRayImageReceptorTranslation = new Element(805437453, 'XRayImageReceptorTranslation', 'DS', '3', '3002000D', undefined)
exports.XRayImageReceptorAngle = new Element(805437454, 'XRayImageReceptorAngle', 'DS', '1', '3002000E', undefined)
exports.RTImageOrientation = new Element(805437456, 'RTImageOrientation', 'DS', '6', '30020010', undefined)
exports.ImagePlanePixelSpacing = new Element(805437457, 'ImagePlanePixelSpacing', 'DS', '2', '30020011', undefined)
exports.RTImagePosition = new Element(805437458, 'RTImagePosition', 'DS', '2', '30020012', undefined)
exports.RadiationMachineName = new Element(805437472, 'RadiationMachineName', 'SH', '1', '30020020', undefined)
exports.RadiationMachineSAD = new Element(805437474, 'RadiationMachineSAD', 'DS', '1', '30020022', undefined)
exports.RadiationMachineSSD = new Element(805437476, 'RadiationMachineSSD', 'DS', '1', '30020024', undefined)
exports.RTImageSID = new Element(805437478, 'RTImageSID', 'DS', '1', '30020026', undefined)
exports.SourceToReferenceObjectDistance = new Element(805437480, 'SourceToReferenceObjectDistance', 'DS', '1', '30020028', undefined)
exports.FractionNumber = new Element(805437481, 'FractionNumber', 'IS', '1', '30020029', undefined)
exports.ExposureSequence = new Element(805437488, 'ExposureSequence', 'SQ', '1', '30020030', undefined)
exports.MetersetExposure = new Element(805437490, 'MetersetExposure', 'DS', '1', '30020032', undefined)
exports.DiaphragmPosition = new Element(805437492, 'DiaphragmPosition', 'DS', '4', '30020034', undefined)
exports.FluenceMapSequence = new Element(805437504, 'FluenceMapSequence', 'SQ', '1', '30020040', undefined)
exports.FluenceDataSource = new Element(805437505, 'FluenceDataSource', 'CS', '1', '30020041', undefined)
exports.FluenceDataScale = new Element(805437506, 'FluenceDataScale', 'DS', '1', '30020042', undefined)
exports.PrimaryFluenceModeSequence = new Element(805437520, 'PrimaryFluenceModeSequence', 'SQ', '1', '30020050', undefined)
exports.FluenceMode = new Element(805437521, 'FluenceMode', 'CS', '1', '30020051', undefined)
exports.FluenceModeID = new Element(805437522, 'FluenceModeID', 'SH', '1', '30020052', undefined)
exports.DVHType = new Element(805568513, 'DVHType', 'CS', '1', '30040001', undefined)
exports.DoseUnits = new Element(805568514, 'DoseUnits', 'CS', '1', '30040002', undefined)
exports.DoseType = new Element(805568516, 'DoseType', 'CS', '1', '30040004', undefined)
exports.SpatialTransformOfDose = new Element(805568517, 'SpatialTransformOfDose', 'CS', '1', '30040005', undefined)
exports.DoseComment = new Element(805568518, 'DoseComment', 'LO', '1', '30040006', undefined)
exports.NormalizationPoint = new Element(805568520, 'NormalizationPoint', 'DS', '3', '30040008', undefined)
exports.DoseSummationType = new Element(805568522, 'DoseSummationType', 'CS', '1', '3004000A', undefined)
exports.GridFrameOffsetVector = new Element(805568524, 'GridFrameOffsetVector', 'DS', '2-n', '3004000C', undefined)
exports.DoseGridScaling = new Element(805568526, 'DoseGridScaling', 'DS', '1', '3004000E', undefined)
exports.RTDoseROISequence = new Element(805568528, 'RTDoseROISequence', 'SQ', '1', '30040010', undefined)
exports.DoseValue = new Element(805568530, 'DoseValue', 'DS', '1', '30040012', undefined)
exports.TissueHeterogeneityCorrection = new Element(805568532, 'TissueHeterogeneityCorrection', 'CS', '1-3', '30040014', undefined)
exports.DVHNormalizationPoint = new Element(805568576, 'DVHNormalizationPoint', 'DS', '3', '30040040', undefined)
exports.DVHNormalizationDoseValue = new Element(805568578, 'DVHNormalizationDoseValue', 'DS', '1', '30040042', undefined)
exports.DVHSequence = new Element(805568592, 'DVHSequence', 'SQ', '1', '30040050', undefined)
exports.DVHDoseScaling = new Element(805568594, 'DVHDoseScaling', 'DS', '1', '30040052', undefined)
exports.DVHVolumeUnits = new Element(805568596, 'DVHVolumeUnits', 'CS', '1', '30040054', undefined)
exports.DVHNumberOfBins = new Element(805568598, 'DVHNumberOfBins', 'IS', '1', '30040056', undefined)
exports.DVHData = new Element(805568600, 'DVHData', 'DS', '2-2n', '30040058', undefined)
exports.DVHReferencedROISequence = new Element(805568608, 'DVHReferencedROISequence', 'SQ', '1', '30040060', undefined)
exports.DVHROIContributionType = new Element(805568610, 'DVHROIContributionType', 'CS', '1', '30040062', undefined)
exports.DVHMinimumDose = new Element(805568624, 'DVHMinimumDose', 'DS', '1', '30040070', undefined)
exports.DVHMaximumDose = new Element(805568626, 'DVHMaximumDose', 'DS', '1', '30040072', undefined)
exports.DVHMeanDose = new Element(805568628, 'DVHMeanDose', 'DS', '1', '30040074', undefined)
exports.StructureSetLabel = new Element(805699586, 'StructureSetLabel', 'SH', '1', '30060002', undefined)
exports.StructureSetName = new Element(805699588, 'StructureSetName', 'LO', '1', '30060004', undefined)
exports.StructureSetDescription = new Element(805699590, 'StructureSetDescription', 'ST', '1', '30060006', undefined)
exports.StructureSetDate = new Element(805699592, 'StructureSetDate', 'DA', '1', '30060008', undefined)
exports.StructureSetTime = new Element(805699593, 'StructureSetTime', 'TM', '1', '30060009', undefined)
exports.ReferencedFrameOfReferenceSequence = new Element(805699600, 'ReferencedFrameOfReferenceSequence', 'SQ', '1', '30060010', undefined)
exports.RTReferencedStudySequence = new Element(805699602, 'RTReferencedStudySequence', 'SQ', '1', '30060012', undefined)
exports.RTReferencedSeriesSequence = new Element(805699604, 'RTReferencedSeriesSequence', 'SQ', '1', '30060014', undefined)
exports.ContourImageSequence = new Element(805699606, 'ContourImageSequence', 'SQ', '1', '30060016', undefined)
exports.PredecessorStructureSetSequence = new Element(805699608, 'PredecessorStructureSetSequence', 'SQ', '1', '30060018', undefined)
exports.StructureSetROISequence = new Element(805699616, 'StructureSetROISequence', 'SQ', '1', '30060020', undefined)
exports.ROINumber = new Element(805699618, 'ROINumber', 'IS', '1', '30060022', undefined)
exports.ReferencedFrameOfReferenceUID = new Element(805699620, 'ReferencedFrameOfReferenceUID', 'UI', '1', '30060024', undefined)
exports.ROIName = new Element(805699622, 'ROIName', 'LO', '1', '30060026', undefined)
exports.ROIDescription = new Element(805699624, 'ROIDescription', 'ST', '1', '30060028', undefined)
exports.ROIDisplayColor = new Element(805699626, 'ROIDisplayColor', 'IS', '3', '3006002A', undefined)
exports.ROIVolume = new Element(805699628, 'ROIVolume', 'DS', '1', '3006002C', undefined)
exports.RTRelatedROISequence = new Element(805699632, 'RTRelatedROISequence', 'SQ', '1', '30060030', undefined)
exports.RTROIRelationship = new Element(805699635, 'RTROIRelationship', 'CS', '1', '30060033', undefined)
exports.ROIGenerationAlgorithm = new Element(805699638, 'ROIGenerationAlgorithm', 'CS', '1', '30060036', undefined)
exports.ROIGenerationDescription = new Element(805699640, 'ROIGenerationDescription', 'LO', '1', '30060038', undefined)
exports.ROIContourSequence = new Element(805699641, 'ROIContourSequence', 'SQ', '1', '30060039', undefined)
exports.ContourSequence = new Element(805699648, 'ContourSequence', 'SQ', '1', '30060040', undefined)
exports.ContourGeometricType = new Element(805699650, 'ContourGeometricType', 'CS', '1', '30060042', undefined)
exports.ContourSlabThickness = new Element(805699652, 'ContourSlabThickness', 'DS', '1', '30060044', undefined)
exports.ContourOffsetVector = new Element(805699653, 'ContourOffsetVector', 'DS', '3', '30060045', undefined)
exports.NumberOfContourPoints = new Element(805699654, 'NumberOfContourPoints', 'IS', '1', '30060046', undefined)
exports.ContourNumber = new Element(805699656, 'ContourNumber', 'IS', '1', '30060048', undefined)
exports.AttachedContours = new Element(805699657, 'AttachedContours', 'IS', '1-n', '30060049', undefined)
exports.ContourData = new Element(805699664, 'ContourData', 'DS', '3-3n', '30060050', undefined)
exports.RTROIObservationsSequence = new Element(805699712, 'RTROIObservationsSequence', 'SQ', '1', '30060080', undefined)
exports.ObservationNumber = new Element(805699714, 'ObservationNumber', 'IS', '1', '30060082', undefined)
exports.ReferencedROINumber = new Element(805699716, 'ReferencedROINumber', 'IS', '1', '30060084', undefined)
exports.ROIObservationLabel = new Element(805699717, 'ROIObservationLabel', 'SH', '1', '30060085', undefined)
exports.RTROIIdentificationCodeSequence = new Element(805699718, 'RTROIIdentificationCodeSequence', 'SQ', '1', '30060086', undefined)
exports.ROIObservationDescription = new Element(805699720, 'ROIObservationDescription', 'ST', '1', '30060088', undefined)
exports.RelatedRTROIObservationsSequence = new Element(805699744, 'RelatedRTROIObservationsSequence', 'SQ', '1', '300600A0', undefined)
exports.RTROIInterpretedType = new Element(805699748, 'RTROIInterpretedType', 'CS', '1', '300600A4', undefined)
exports.ROIInterpreter = new Element(805699750, 'ROIInterpreter', 'PN', '1', '300600A6', undefined)
exports.ROIPhysicalPropertiesSequence = new Element(805699760, 'ROIPhysicalPropertiesSequence', 'SQ', '1', '300600B0', undefined)
exports.ROIPhysicalProperty = new Element(805699762, 'ROIPhysicalProperty', 'CS', '1', '300600B2', undefined)
exports.ROIPhysicalPropertyValue = new Element(805699764, 'ROIPhysicalPropertyValue', 'DS', '1', '300600B4', undefined)
exports.ROIElementalCompositionSequence = new Element(805699766, 'ROIElementalCompositionSequence', 'SQ', '1', '300600B6', undefined)
exports.ROIElementalCompositionAtomicNumber = new Element(805699767, 'ROIElementalCompositionAtomicNumber', 'US', '1', '300600B7', undefined)
exports.ROIElementalCompositionAtomicMassFraction = new Element(805699768, 'ROIElementalCompositionAtomicMassFraction', 'FL', '1', '300600B8', undefined)
exports.AdditionalRTROIIdentificationCodeSequence = new Element(805699769, 'AdditionalRTROIIdentificationCodeSequence', 'SQ', '1', '300600B9', undefined)
exports.FrameOfReferenceRelationshipSequence = new Element(805699776, 'FrameOfReferenceRelationshipSequence', 'SQ', '1', '300600C0', true)
exports.RelatedFrameOfReferenceUID = new Element(805699778, 'RelatedFrameOfReferenceUID', 'UI', '1', '300600C2', true)
exports.FrameOfReferenceTransformationType = new Element(805699780, 'FrameOfReferenceTransformationType', 'CS', '1', '300600C4', true)
exports.FrameOfReferenceTransformationMatrix = new Element(805699782, 'FrameOfReferenceTransformationMatrix', 'DS', '16', '300600C6', undefined)
exports.FrameOfReferenceTransformationComment = new Element(805699784, 'FrameOfReferenceTransformationComment', 'LO', '1', '300600C8', undefined)
exports.MeasuredDoseReferenceSequence = new Element(805830672, 'MeasuredDoseReferenceSequence', 'SQ', '1', '30080010', undefined)
exports.MeasuredDoseDescription = new Element(805830674, 'MeasuredDoseDescription', 'ST', '1', '30080012', undefined)
exports.MeasuredDoseType = new Element(805830676, 'MeasuredDoseType', 'CS', '1', '30080014', undefined)
exports.MeasuredDoseValue = new Element(805830678, 'MeasuredDoseValue', 'DS', '1', '30080016', undefined)
exports.TreatmentSessionBeamSequence = new Element(805830688, 'TreatmentSessionBeamSequence', 'SQ', '1', '30080020', undefined)
exports.TreatmentSessionIonBeamSequence = new Element(805830689, 'TreatmentSessionIonBeamSequence', 'SQ', '1', '30080021', undefined)
exports.CurrentFractionNumber = new Element(805830690, 'CurrentFractionNumber', 'IS', '1', '30080022', undefined)
exports.TreatmentControlPointDate = new Element(805830692, 'TreatmentControlPointDate', 'DA', '1', '30080024', undefined)
exports.TreatmentControlPointTime = new Element(805830693, 'TreatmentControlPointTime', 'TM', '1', '30080025', undefined)
exports.TreatmentTerminationStatus = new Element(805830698, 'TreatmentTerminationStatus', 'CS', '1', '3008002A', undefined)
exports.TreatmentTerminationCode = new Element(805830699, 'TreatmentTerminationCode', 'SH', '1', '3008002B', undefined)
exports.TreatmentVerificationStatus = new Element(805830700, 'TreatmentVerificationStatus', 'CS', '1', '3008002C', undefined)
exports.ReferencedTreatmentRecordSequence = new Element(805830704, 'ReferencedTreatmentRecordSequence', 'SQ', '1', '30080030', undefined)
exports.SpecifiedPrimaryMeterset = new Element(805830706, 'SpecifiedPrimaryMeterset', 'DS', '1', '30080032', undefined)
exports.SpecifiedSecondaryMeterset = new Element(805830707, 'SpecifiedSecondaryMeterset', 'DS', '1', '30080033', undefined)
exports.DeliveredPrimaryMeterset = new Element(805830710, 'DeliveredPrimaryMeterset', 'DS', '1', '30080036', undefined)
exports.DeliveredSecondaryMeterset = new Element(805830711, 'DeliveredSecondaryMeterset', 'DS', '1', '30080037', undefined)
exports.SpecifiedTreatmentTime = new Element(805830714, 'SpecifiedTreatmentTime', 'DS', '1', '3008003A', undefined)
exports.DeliveredTreatmentTime = new Element(805830715, 'DeliveredTreatmentTime', 'DS', '1', '3008003B', undefined)
exports.ControlPointDeliverySequence = new Element(805830720, 'ControlPointDeliverySequence', 'SQ', '1', '30080040', undefined)
exports.IonControlPointDeliverySequence = new Element(805830721, 'IonControlPointDeliverySequence', 'SQ', '1', '30080041', undefined)
exports.SpecifiedMeterset = new Element(805830722, 'SpecifiedMeterset', 'DS', '1', '30080042', undefined)
exports.DeliveredMeterset = new Element(805830724, 'DeliveredMeterset', 'DS', '1', '30080044', undefined)
exports.MetersetRateSet = new Element(805830725, 'MetersetRateSet', 'FL', '1', '30080045', undefined)
exports.MetersetRateDelivered = new Element(805830726, 'MetersetRateDelivered', 'FL', '1', '30080046', undefined)
exports.ScanSpotMetersetsDelivered = new Element(805830727, 'ScanSpotMetersetsDelivered', 'FL', '1-n', '30080047', undefined)
exports.DoseRateDelivered = new Element(805830728, 'DoseRateDelivered', 'DS', '1', '30080048', undefined)
exports.TreatmentSummaryCalculatedDoseReferenceSequence = new Element(805830736, 'TreatmentSummaryCalculatedDoseReferenceSequence', 'SQ', '1', '30080050', undefined)
exports.CumulativeDoseToDoseReference = new Element(805830738, 'CumulativeDoseToDoseReference', 'DS', '1', '30080052', undefined)
exports.FirstTreatmentDate = new Element(805830740, 'FirstTreatmentDate', 'DA', '1', '30080054', undefined)
exports.MostRecentTreatmentDate = new Element(805830742, 'MostRecentTreatmentDate', 'DA', '1', '30080056', undefined)
exports.NumberOfFractionsDelivered = new Element(805830746, 'NumberOfFractionsDelivered', 'IS', '1', '3008005A', undefined)
exports.OverrideSequence = new Element(805830752, 'OverrideSequence', 'SQ', '1', '30080060', undefined)
exports.ParameterSequencePointer = new Element(805830753, 'ParameterSequencePointer', 'AT', '1', '30080061', undefined)
exports.OverrideParameterPointer = new Element(805830754, 'OverrideParameterPointer', 'AT', '1', '30080062', undefined)
exports.ParameterItemIndex = new Element(805830755, 'ParameterItemIndex', 'IS', '1', '30080063', undefined)
exports.MeasuredDoseReferenceNumber = new Element(805830756, 'MeasuredDoseReferenceNumber', 'IS', '1', '30080064', undefined)
exports.ParameterPointer = new Element(805830757, 'ParameterPointer', 'AT', '1', '30080065', undefined)
exports.OverrideReason = new Element(805830758, 'OverrideReason', 'ST', '1', '30080066', undefined)
exports.CorrectedParameterSequence = new Element(805830760, 'CorrectedParameterSequence', 'SQ', '1', '30080068', undefined)
exports.CorrectionValue = new Element(805830762, 'CorrectionValue', 'FL', '1', '3008006A', undefined)
exports.CalculatedDoseReferenceSequence = new Element(805830768, 'CalculatedDoseReferenceSequence', 'SQ', '1', '30080070', undefined)
exports.CalculatedDoseReferenceNumber = new Element(805830770, 'CalculatedDoseReferenceNumber', 'IS', '1', '30080072', undefined)
exports.CalculatedDoseReferenceDescription = new Element(805830772, 'CalculatedDoseReferenceDescription', 'ST', '1', '30080074', undefined)
exports.CalculatedDoseReferenceDoseValue = new Element(805830774, 'CalculatedDoseReferenceDoseValue', 'DS', '1', '30080076', undefined)
exports.StartMeterset = new Element(805830776, 'StartMeterset', 'DS', '1', '30080078', undefined)
exports.EndMeterset = new Element(805830778, 'EndMeterset', 'DS', '1', '3008007A', undefined)
exports.ReferencedMeasuredDoseReferenceSequence = new Element(805830784, 'ReferencedMeasuredDoseReferenceSequence', 'SQ', '1', '30080080', undefined)
exports.ReferencedMeasuredDoseReferenceNumber = new Element(805830786, 'ReferencedMeasuredDoseReferenceNumber', 'IS', '1', '30080082', undefined)
exports.ReferencedCalculatedDoseReferenceSequence = new Element(805830800, 'ReferencedCalculatedDoseReferenceSequence', 'SQ', '1', '30080090', undefined)
exports.ReferencedCalculatedDoseReferenceNumber = new Element(805830802, 'ReferencedCalculatedDoseReferenceNumber', 'IS', '1', '30080092', undefined)
exports.BeamLimitingDeviceLeafPairsSequence = new Element(805830816, 'BeamLimitingDeviceLeafPairsSequence', 'SQ', '1', '300800A0', undefined)
exports.RecordedWedgeSequence = new Element(805830832, 'RecordedWedgeSequence', 'SQ', '1', '300800B0', undefined)
exports.RecordedCompensatorSequence = new Element(805830848, 'RecordedCompensatorSequence', 'SQ', '1', '300800C0', undefined)
exports.RecordedBlockSequence = new Element(805830864, 'RecordedBlockSequence', 'SQ', '1', '300800D0', undefined)
exports.TreatmentSummaryMeasuredDoseReferenceSequence = new Element(805830880, 'TreatmentSummaryMeasuredDoseReferenceSequence', 'SQ', '1', '300800E0', undefined)
exports.RecordedSnoutSequence = new Element(805830896, 'RecordedSnoutSequence', 'SQ', '1', '300800F0', undefined)
exports.RecordedRangeShifterSequence = new Element(805830898, 'RecordedRangeShifterSequence', 'SQ', '1', '300800F2', undefined)
exports.RecordedLateralSpreadingDeviceSequence = new Element(805830900, 'RecordedLateralSpreadingDeviceSequence', 'SQ', '1', '300800F4', undefined)
exports.RecordedRangeModulatorSequence = new Element(805830902, 'RecordedRangeModulatorSequence', 'SQ', '1', '300800F6', undefined)
exports.RecordedSourceSequence = new Element(805830912, 'RecordedSourceSequence', 'SQ', '1', '30080100', undefined)
exports.SourceSerialNumber = new Element(805830917, 'SourceSerialNumber', 'LO', '1', '30080105', undefined)
exports.TreatmentSessionApplicationSetupSequence = new Element(805830928, 'TreatmentSessionApplicationSetupSequence', 'SQ', '1', '30080110', undefined)
exports.ApplicationSetupCheck = new Element(805830934, 'ApplicationSetupCheck', 'CS', '1', '30080116', undefined)
exports.RecordedBrachyAccessoryDeviceSequence = new Element(805830944, 'RecordedBrachyAccessoryDeviceSequence', 'SQ', '1', '30080120', undefined)
exports.ReferencedBrachyAccessoryDeviceNumber = new Element(805830946, 'ReferencedBrachyAccessoryDeviceNumber', 'IS', '1', '30080122', undefined)
exports.RecordedChannelSequence = new Element(805830960, 'RecordedChannelSequence', 'SQ', '1', '30080130', undefined)
exports.SpecifiedChannelTotalTime = new Element(805830962, 'SpecifiedChannelTotalTime', 'DS', '1', '30080132', undefined)
exports.DeliveredChannelTotalTime = new Element(805830964, 'DeliveredChannelTotalTime', 'DS', '1', '30080134', undefined)
exports.SpecifiedNumberOfPulses = new Element(805830966, 'SpecifiedNumberOfPulses', 'IS', '1', '30080136', undefined)
exports.DeliveredNumberOfPulses = new Element(805830968, 'DeliveredNumberOfPulses', 'IS', '1', '30080138', undefined)
exports.SpecifiedPulseRepetitionInterval = new Element(805830970, 'SpecifiedPulseRepetitionInterval', 'DS', '1', '3008013A', undefined)
exports.DeliveredPulseRepetitionInterval = new Element(805830972, 'DeliveredPulseRepetitionInterval', 'DS', '1', '3008013C', undefined)
exports.RecordedSourceApplicatorSequence = new Element(805830976, 'RecordedSourceApplicatorSequence', 'SQ', '1', '30080140', undefined)
exports.ReferencedSourceApplicatorNumber = new Element(805830978, 'ReferencedSourceApplicatorNumber', 'IS', '1', '30080142', undefined)
exports.RecordedChannelShieldSequence = new Element(805830992, 'RecordedChannelShieldSequence', 'SQ', '1', '30080150', undefined)
exports.ReferencedChannelShieldNumber = new Element(805830994, 'ReferencedChannelShieldNumber', 'IS', '1', '30080152', undefined)
exports.BrachyControlPointDeliveredSequence = new Element(805831008, 'BrachyControlPointDeliveredSequence', 'SQ', '1', '30080160', undefined)
exports.SafePositionExitDate = new Element(805831010, 'SafePositionExitDate', 'DA', '1', '30080162', undefined)
exports.SafePositionExitTime = new Element(805831012, 'SafePositionExitTime', 'TM', '1', '30080164', undefined)
exports.SafePositionReturnDate = new Element(805831014, 'SafePositionReturnDate', 'DA', '1', '30080166', undefined)
exports.SafePositionReturnTime = new Element(805831016, 'SafePositionReturnTime', 'TM', '1', '30080168', undefined)
exports.PulseSpecificBrachyControlPointDeliveredSequence = new Element(805831025, 'PulseSpecificBrachyControlPointDeliveredSequence', 'SQ', '1', '30080171', undefined)
exports.PulseNumber = new Element(805831026, 'PulseNumber', 'US', '1', '30080172', undefined)
exports.BrachyPulseControlPointDeliveredSequence = new Element(805831027, 'BrachyPulseControlPointDeliveredSequence', 'SQ', '1', '30080173', undefined)
exports.CurrentTreatmentStatus = new Element(805831168, 'CurrentTreatmentStatus', 'CS', '1', '30080200', undefined)
exports.TreatmentStatusComment = new Element(805831170, 'TreatmentStatusComment', 'ST', '1', '30080202', undefined)
exports.FractionGroupSummarySequence = new Element(805831200, 'FractionGroupSummarySequence', 'SQ', '1', '30080220', undefined)
exports.ReferencedFractionNumber = new Element(805831203, 'ReferencedFractionNumber', 'IS', '1', '30080223', undefined)
exports.FractionGroupType = new Element(805831204, 'FractionGroupType', 'CS', '1', '30080224', undefined)
exports.BeamStopperPosition = new Element(805831216, 'BeamStopperPosition', 'CS', '1', '30080230', undefined)
exports.FractionStatusSummarySequence = new Element(805831232, 'FractionStatusSummarySequence', 'SQ', '1', '30080240', undefined)
exports.TreatmentDate = new Element(805831248, 'TreatmentDate', 'DA', '1', '30080250', undefined)
exports.TreatmentTime = new Element(805831249, 'TreatmentTime', 'TM', '1', '30080251', undefined)
exports.RTPlanLabel = new Element(805961730, 'RTPlanLabel', 'SH', '1', '300A0002', undefined)
exports.RTPlanName = new Element(805961731, 'RTPlanName', 'LO', '1', '300A0003', undefined)
exports.RTPlanDescription = new Element(805961732, 'RTPlanDescription', 'ST', '1', '300A0004', undefined)
exports.RTPlanDate = new Element(805961734, 'RTPlanDate', 'DA', '1', '300A0006', undefined)
exports.RTPlanTime = new Element(805961735, 'RTPlanTime', 'TM', '1', '300A0007', undefined)
exports.TreatmentProtocols = new Element(805961737, 'TreatmentProtocols', 'LO', '1-n', '300A0009', undefined)
exports.PlanIntent = new Element(805961738, 'PlanIntent', 'CS', '1', '300A000A', undefined)
exports.TreatmentSites = new Element(805961739, 'TreatmentSites', 'LO', '1-n', '300A000B', undefined)
exports.RTPlanGeometry = new Element(805961740, 'RTPlanGeometry', 'CS', '1', '300A000C', undefined)
exports.PrescriptionDescription = new Element(805961742, 'PrescriptionDescription', 'ST', '1', '300A000E', undefined)
exports.DoseReferenceSequence = new Element(805961744, 'DoseReferenceSequence', 'SQ', '1', '300A0010', undefined)
exports.DoseReferenceNumber = new Element(805961746, 'DoseReferenceNumber', 'IS', '1', '300A0012', undefined)
exports.DoseReferenceUID = new Element(805961747, 'DoseReferenceUID', 'UI', '1', '300A0013', undefined)
exports.DoseReferenceStructureType = new Element(805961748, 'DoseReferenceStructureType', 'CS', '1', '300A0014', undefined)
exports.NominalBeamEnergyUnit = new Element(805961749, 'NominalBeamEnergyUnit', 'CS', '1', '300A0015', undefined)
exports.DoseReferenceDescription = new Element(805961750, 'DoseReferenceDescription', 'LO', '1', '300A0016', undefined)
exports.DoseReferencePointCoordinates = new Element(805961752, 'DoseReferencePointCoordinates', 'DS', '3', '300A0018', undefined)
exports.NominalPriorDose = new Element(805961754, 'NominalPriorDose', 'DS', '1', '300A001A', undefined)
exports.DoseReferenceType = new Element(805961760, 'DoseReferenceType', 'CS', '1', '300A0020', undefined)
exports.ConstraintWeight = new Element(805961761, 'ConstraintWeight', 'DS', '1', '300A0021', undefined)
exports.DeliveryWarningDose = new Element(805961762, 'DeliveryWarningDose', 'DS', '1', '300A0022', undefined)
exports.DeliveryMaximumDose = new Element(805961763, 'DeliveryMaximumDose', 'DS', '1', '300A0023', undefined)
exports.TargetMinimumDose = new Element(805961765, 'TargetMinimumDose', 'DS', '1', '300A0025', undefined)
exports.TargetPrescriptionDose = new Element(805961766, 'TargetPrescriptionDose', 'DS', '1', '300A0026', undefined)
exports.TargetMaximumDose = new Element(805961767, 'TargetMaximumDose', 'DS', '1', '300A0027', undefined)
exports.TargetUnderdoseVolumeFraction = new Element(805961768, 'TargetUnderdoseVolumeFraction', 'DS', '1', '300A0028', undefined)
exports.OrganAtRiskFullVolumeDose = new Element(805961770, 'OrganAtRiskFullVolumeDose', 'DS', '1', '300A002A', undefined)
exports.OrganAtRiskLimitDose = new Element(805961771, 'OrganAtRiskLimitDose', 'DS', '1', '300A002B', undefined)
exports.OrganAtRiskMaximumDose = new Element(805961772, 'OrganAtRiskMaximumDose', 'DS', '1', '300A002C', undefined)
exports.OrganAtRiskOverdoseVolumeFraction = new Element(805961773, 'OrganAtRiskOverdoseVolumeFraction', 'DS', '1', '300A002D', undefined)
exports.ToleranceTableSequence = new Element(805961792, 'ToleranceTableSequence', 'SQ', '1', '300A0040', undefined)
exports.ToleranceTableNumber = new Element(805961794, 'ToleranceTableNumber', 'IS', '1', '300A0042', undefined)
exports.ToleranceTableLabel = new Element(805961795, 'ToleranceTableLabel', 'SH', '1', '300A0043', undefined)
exports.GantryAngleTolerance = new Element(805961796, 'GantryAngleTolerance', 'DS', '1', '300A0044', undefined)
exports.BeamLimitingDeviceAngleTolerance = new Element(805961798, 'BeamLimitingDeviceAngleTolerance', 'DS', '1', '300A0046', undefined)
exports.BeamLimitingDeviceToleranceSequence = new Element(805961800, 'BeamLimitingDeviceToleranceSequence', 'SQ', '1', '300A0048', undefined)
exports.BeamLimitingDevicePositionTolerance = new Element(805961802, 'BeamLimitingDevicePositionTolerance', 'DS', '1', '300A004A', undefined)
exports.SnoutPositionTolerance = new Element(805961803, 'SnoutPositionTolerance', 'FL', '1', '300A004B', undefined)
exports.PatientSupportAngleTolerance = new Element(805961804, 'PatientSupportAngleTolerance', 'DS', '1', '300A004C', undefined)
exports.TableTopEccentricAngleTolerance = new Element(805961806, 'TableTopEccentricAngleTolerance', 'DS', '1', '300A004E', undefined)
exports.TableTopPitchAngleTolerance = new Element(805961807, 'TableTopPitchAngleTolerance', 'FL', '1', '300A004F', undefined)
exports.TableTopRollAngleTolerance = new Element(805961808, 'TableTopRollAngleTolerance', 'FL', '1', '300A0050', undefined)
exports.TableTopVerticalPositionTolerance = new Element(805961809, 'TableTopVerticalPositionTolerance', 'DS', '1', '300A0051', undefined)
exports.TableTopLongitudinalPositionTolerance = new Element(805961810, 'TableTopLongitudinalPositionTolerance', 'DS', '1', '300A0052', undefined)
exports.TableTopLateralPositionTolerance = new Element(805961811, 'TableTopLateralPositionTolerance', 'DS', '1', '300A0053', undefined)
exports.RTPlanRelationship = new Element(805961813, 'RTPlanRelationship', 'CS', '1', '300A0055', undefined)
exports.FractionGroupSequence = new Element(805961840, 'FractionGroupSequence', 'SQ', '1', '300A0070', undefined)
exports.FractionGroupNumber = new Element(805961841, 'FractionGroupNumber', 'IS', '1', '300A0071', undefined)
exports.FractionGroupDescription = new Element(805961842, 'FractionGroupDescription', 'LO', '1', '300A0072', undefined)
exports.NumberOfFractionsPlanned = new Element(805961848, 'NumberOfFractionsPlanned', 'IS', '1', '300A0078', undefined)
exports.NumberOfFractionPatternDigitsPerDay = new Element(805961849, 'NumberOfFractionPatternDigitsPerDay', 'IS', '1', '300A0079', undefined)
exports.RepeatFractionCycleLength = new Element(805961850, 'RepeatFractionCycleLength', 'IS', '1', '300A007A', undefined)
exports.FractionPattern = new Element(805961851, 'FractionPattern', 'LT', '1', '300A007B', undefined)
exports.NumberOfBeams = new Element(805961856, 'NumberOfBeams', 'IS', '1', '300A0080', undefined)
exports.BeamDoseSpecificationPoint = new Element(805961858, 'BeamDoseSpecificationPoint', 'DS', '3', '300A0082', undefined)
exports.BeamDose = new Element(805961860, 'BeamDose', 'DS', '1', '300A0084', undefined)
exports.BeamMeterset = new Element(805961862, 'BeamMeterset', 'DS', '1', '300A0086', undefined)
exports.BeamDosePointDepth = new Element(805961864, 'BeamDosePointDepth', 'FL', '1', '300A0088', true)
exports.BeamDosePointEquivalentDepth = new Element(805961865, 'BeamDosePointEquivalentDepth', 'FL', '1', '300A0089', true)
exports.BeamDosePointSSD = new Element(805961866, 'BeamDosePointSSD', 'FL', '1', '300A008A', true)
exports.BeamDoseMeaning = new Element(805961867, 'BeamDoseMeaning', 'CS', '1', '300A008B', undefined)
exports.BeamDoseVerificationControlPointSequence = new Element(805961868, 'BeamDoseVerificationControlPointSequence', 'SQ', '1', '300A008C', undefined)
exports.AverageBeamDosePointDepth = new Element(805961869, 'AverageBeamDosePointDepth', 'FL', '1', '300A008D', undefined)
exports.AverageBeamDosePointEquivalentDepth = new Element(805961870, 'AverageBeamDosePointEquivalentDepth', 'FL', '1', '300A008E', undefined)
exports.AverageBeamDosePointSSD = new Element(805961871, 'AverageBeamDosePointSSD', 'FL', '1', '300A008F', undefined)
exports.NumberOfBrachyApplicationSetups = new Element(805961888, 'NumberOfBrachyApplicationSetups', 'IS', '1', '300A00A0', undefined)
exports.BrachyApplicationSetupDoseSpecificationPoint = new Element(805961890, 'BrachyApplicationSetupDoseSpecificationPoint', 'DS', '3', '300A00A2', undefined)
exports.BrachyApplicationSetupDose = new Element(805961892, 'BrachyApplicationSetupDose', 'DS', '1', '300A00A4', undefined)
exports.BeamSequence = new Element(805961904, 'BeamSequence', 'SQ', '1', '300A00B0', undefined)
exports.TreatmentMachineName = new Element(805961906, 'TreatmentMachineName', 'SH', '1', '300A00B2', undefined)
exports.PrimaryDosimeterUnit = new Element(805961907, 'PrimaryDosimeterUnit', 'CS', '1', '300A00B3', undefined)
exports.SourceAxisDistance = new Element(805961908, 'SourceAxisDistance', 'DS', '1', '300A00B4', undefined)
exports.BeamLimitingDeviceSequence = new Element(805961910, 'BeamLimitingDeviceSequence', 'SQ', '1', '300A00B6', undefined)
exports.RTBeamLimitingDeviceType = new Element(805961912, 'RTBeamLimitingDeviceType', 'CS', '1', '300A00B8', undefined)
exports.SourceToBeamLimitingDeviceDistance = new Element(805961914, 'SourceToBeamLimitingDeviceDistance', 'DS', '1', '300A00BA', undefined)
exports.IsocenterToBeamLimitingDeviceDistance = new Element(805961915, 'IsocenterToBeamLimitingDeviceDistance', 'FL', '1', '300A00BB', undefined)
exports.NumberOfLeafJawPairs = new Element(805961916, 'NumberOfLeafJawPairs', 'IS', '1', '300A00BC', undefined)
exports.LeafPositionBoundaries = new Element(805961918, 'LeafPositionBoundaries', 'DS', '3-n', '300A00BE', undefined)
exports.BeamNumber = new Element(805961920, 'BeamNumber', 'IS', '1', '300A00C0', undefined)
exports.BeamName = new Element(805961922, 'BeamName', 'LO', '1', '300A00C2', undefined)
exports.BeamDescription = new Element(805961923, 'BeamDescription', 'ST', '1', '300A00C3', undefined)
exports.BeamType = new Element(805961924, 'BeamType', 'CS', '1', '300A00C4', undefined)
exports.BeamDeliveryDurationLimit = new Element(805961925, 'BeamDeliveryDurationLimit', 'FD', '1', '300A00C5', undefined)
exports.RadiationType = new Element(805961926, 'RadiationType', 'CS', '1', '300A00C6', undefined)
exports.HighDoseTechniqueType = new Element(805961927, 'HighDoseTechniqueType', 'CS', '1', '300A00C7', undefined)
exports.ReferenceImageNumber = new Element(805961928, 'ReferenceImageNumber', 'IS', '1', '300A00C8', undefined)
exports.PlannedVerificationImageSequence = new Element(805961930, 'PlannedVerificationImageSequence', 'SQ', '1', '300A00CA', undefined)
exports.ImagingDeviceSpecificAcquisitionParameters = new Element(805961932, 'ImagingDeviceSpecificAcquisitionParameters', 'LO', '1-n', '300A00CC', undefined)
exports.TreatmentDeliveryType = new Element(805961934, 'TreatmentDeliveryType', 'CS', '1', '300A00CE', undefined)
exports.NumberOfWedges = new Element(805961936, 'NumberOfWedges', 'IS', '1', '300A00D0', undefined)
exports.WedgeSequence = new Element(805961937, 'WedgeSequence', 'SQ', '1', '300A00D1', undefined)
exports.WedgeNumber = new Element(805961938, 'WedgeNumber', 'IS', '1', '300A00D2', undefined)
exports.WedgeType = new Element(805961939, 'WedgeType', 'CS', '1', '300A00D3', undefined)
exports.WedgeID = new Element(805961940, 'WedgeID', 'SH', '1', '300A00D4', undefined)
exports.WedgeAngle = new Element(805961941, 'WedgeAngle', 'IS', '1', '300A00D5', undefined)
exports.WedgeFactor = new Element(805961942, 'WedgeFactor', 'DS', '1', '300A00D6', undefined)
exports.TotalWedgeTrayWaterEquivalentThickness = new Element(805961943, 'TotalWedgeTrayWaterEquivalentThickness', 'FL', '1', '300A00D7', undefined)
exports.WedgeOrientation = new Element(805961944, 'WedgeOrientation', 'DS', '1', '300A00D8', undefined)
exports.IsocenterToWedgeTrayDistance = new Element(805961945, 'IsocenterToWedgeTrayDistance', 'FL', '1', '300A00D9', undefined)
exports.SourceToWedgeTrayDistance = new Element(805961946, 'SourceToWedgeTrayDistance', 'DS', '1', '300A00DA', undefined)
exports.WedgeThinEdgePosition = new Element(805961947, 'WedgeThinEdgePosition', 'FL', '1', '300A00DB', undefined)
exports.BolusID = new Element(805961948, 'BolusID', 'SH', '1', '300A00DC', undefined)
exports.BolusDescription = new Element(805961949, 'BolusDescription', 'ST', '1', '300A00DD', undefined)
exports.NumberOfCompensators = new Element(805961952, 'NumberOfCompensators', 'IS', '1', '300A00E0', undefined)
exports.MaterialID = new Element(805961953, 'MaterialID', 'SH', '1', '300A00E1', undefined)
exports.TotalCompensatorTrayFactor = new Element(805961954, 'TotalCompensatorTrayFactor', 'DS', '1', '300A00E2', undefined)
exports.CompensatorSequence = new Element(805961955, 'CompensatorSequence', 'SQ', '1', '300A00E3', undefined)
exports.CompensatorNumber = new Element(805961956, 'CompensatorNumber', 'IS', '1', '300A00E4', undefined)
exports.CompensatorID = new Element(805961957, 'CompensatorID', 'SH', '1', '300A00E5', undefined)
exports.SourceToCompensatorTrayDistance = new Element(805961958, 'SourceToCompensatorTrayDistance', 'DS', '1', '300A00E6', undefined)
exports.CompensatorRows = new Element(805961959, 'CompensatorRows', 'IS', '1', '300A00E7', undefined)
exports.CompensatorColumns = new Element(805961960, 'CompensatorColumns', 'IS', '1', '300A00E8', undefined)
exports.CompensatorPixelSpacing = new Element(805961961, 'CompensatorPixelSpacing', 'DS', '2', '300A00E9', undefined)
exports.CompensatorPosition = new Element(805961962, 'CompensatorPosition', 'DS', '2', '300A00EA', undefined)
exports.CompensatorTransmissionData = new Element(805961963, 'CompensatorTransmissionData', 'DS', '1-n', '300A00EB', undefined)
exports.CompensatorThicknessData = new Element(805961964, 'CompensatorThicknessData', 'DS', '1-n', '300A00EC', undefined)
exports.NumberOfBoli = new Element(805961965, 'NumberOfBoli', 'IS', '1', '300A00ED', undefined)
exports.CompensatorType = new Element(805961966, 'CompensatorType', 'CS', '1', '300A00EE', undefined)
exports.CompensatorTrayID = new Element(805961967, 'CompensatorTrayID', 'SH', '1', '300A00EF', undefined)
exports.NumberOfBlocks = new Element(805961968, 'NumberOfBlocks', 'IS', '1', '300A00F0', undefined)
exports.TotalBlockTrayFactor = new Element(805961970, 'TotalBlockTrayFactor', 'DS', '1', '300A00F2', undefined)
exports.TotalBlockTrayWaterEquivalentThickness = new Element(805961971, 'TotalBlockTrayWaterEquivalentThickness', 'FL', '1', '300A00F3', undefined)
exports.BlockSequence = new Element(805961972, 'BlockSequence', 'SQ', '1', '300A00F4', undefined)
exports.BlockTrayID = new Element(805961973, 'BlockTrayID', 'SH', '1', '300A00F5', undefined)
exports.SourceToBlockTrayDistance = new Element(805961974, 'SourceToBlockTrayDistance', 'DS', '1', '300A00F6', undefined)
exports.IsocenterToBlockTrayDistance = new Element(805961975, 'IsocenterToBlockTrayDistance', 'FL', '1', '300A00F7', undefined)
exports.BlockType = new Element(805961976, 'BlockType', 'CS', '1', '300A00F8', undefined)
exports.AccessoryCode = new Element(805961977, 'AccessoryCode', 'LO', '1', '300A00F9', undefined)
exports.BlockDivergence = new Element(805961978, 'BlockDivergence', 'CS', '1', '300A00FA', undefined)
exports.BlockMountingPosition = new Element(805961979, 'BlockMountingPosition', 'CS', '1', '300A00FB', undefined)
exports.BlockNumber = new Element(805961980, 'BlockNumber', 'IS', '1', '300A00FC', undefined)
exports.BlockName = new Element(805961982, 'BlockName', 'LO', '1', '300A00FE', undefined)
exports.BlockThickness = new Element(805961984, 'BlockThickness', 'DS', '1', '300A0100', undefined)
exports.BlockTransmission = new Element(805961986, 'BlockTransmission', 'DS', '1', '300A0102', undefined)
exports.BlockNumberOfPoints = new Element(805961988, 'BlockNumberOfPoints', 'IS', '1', '300A0104', undefined)
exports.BlockData = new Element(805961990, 'BlockData', 'DS', '2-2n', '300A0106', undefined)
exports.ApplicatorSequence = new Element(805961991, 'ApplicatorSequence', 'SQ', '1', '300A0107', undefined)
exports.ApplicatorID = new Element(805961992, 'ApplicatorID', 'SH', '1', '300A0108', undefined)
exports.ApplicatorType = new Element(805961993, 'ApplicatorType', 'CS', '1', '300A0109', undefined)
exports.ApplicatorDescription = new Element(805961994, 'ApplicatorDescription', 'LO', '1', '300A010A', undefined)
exports.CumulativeDoseReferenceCoefficient = new Element(805961996, 'CumulativeDoseReferenceCoefficient', 'DS', '1', '300A010C', undefined)
exports.FinalCumulativeMetersetWeight = new Element(805961998, 'FinalCumulativeMetersetWeight', 'DS', '1', '300A010E', undefined)
exports.NumberOfControlPoints = new Element(805962000, 'NumberOfControlPoints', 'IS', '1', '300A0110', undefined)
exports.ControlPointSequence = new Element(805962001, 'ControlPointSequence', 'SQ', '1', '300A0111', undefined)
exports.ControlPointIndex = new Element(805962002, 'ControlPointIndex', 'IS', '1', '300A0112', undefined)
exports.NominalBeamEnergy = new Element(805962004, 'NominalBeamEnergy', 'DS', '1', '300A0114', undefined)
exports.DoseRateSet = new Element(805962005, 'DoseRateSet', 'DS', '1', '300A0115', undefined)
exports.WedgePositionSequence = new Element(805962006, 'WedgePositionSequence', 'SQ', '1', '300A0116', undefined)
exports.WedgePosition = new Element(805962008, 'WedgePosition', 'CS', '1', '300A0118', undefined)
exports.BeamLimitingDevicePositionSequence = new Element(805962010, 'BeamLimitingDevicePositionSequence', 'SQ', '1', '300A011A', undefined)
exports.LeafJawPositions = new Element(805962012, 'LeafJawPositions', 'DS', '2-2n', '300A011C', undefined)
exports.GantryAngle = new Element(805962014, 'GantryAngle', 'DS', '1', '300A011E', undefined)
exports.GantryRotationDirection = new Element(805962015, 'GantryRotationDirection', 'CS', '1', '300A011F', undefined)
exports.BeamLimitingDeviceAngle = new Element(805962016, 'BeamLimitingDeviceAngle', 'DS', '1', '300A0120', undefined)
exports.BeamLimitingDeviceRotationDirection = new Element(805962017, 'BeamLimitingDeviceRotationDirection', 'CS', '1', '300A0121', undefined)
exports.PatientSupportAngle = new Element(805962018, 'PatientSupportAngle', 'DS', '1', '300A0122', undefined)
exports.PatientSupportRotationDirection = new Element(805962019, 'PatientSupportRotationDirection', 'CS', '1', '300A0123', undefined)
exports.TableTopEccentricAxisDistance = new Element(805962020, 'TableTopEccentricAxisDistance', 'DS', '1', '300A0124', undefined)
exports.TableTopEccentricAngle = new Element(805962021, 'TableTopEccentricAngle', 'DS', '1', '300A0125', undefined)
exports.TableTopEccentricRotationDirection = new Element(805962022, 'TableTopEccentricRotationDirection', 'CS', '1', '300A0126', undefined)
exports.TableTopVerticalPosition = new Element(805962024, 'TableTopVerticalPosition', 'DS', '1', '300A0128', undefined)
exports.TableTopLongitudinalPosition = new Element(805962025, 'TableTopLongitudinalPosition', 'DS', '1', '300A0129', undefined)
exports.TableTopLateralPosition = new Element(805962026, 'TableTopLateralPosition', 'DS', '1', '300A012A', undefined)
exports.IsocenterPosition = new Element(805962028, 'IsocenterPosition', 'DS', '3', '300A012C', undefined)
exports.SurfaceEntryPoint = new Element(805962030, 'SurfaceEntryPoint', 'DS', '3', '300A012E', undefined)
exports.SourceToSurfaceDistance = new Element(805962032, 'SourceToSurfaceDistance', 'DS', '1', '300A0130', undefined)
exports.CumulativeMetersetWeight = new Element(805962036, 'CumulativeMetersetWeight', 'DS', '1', '300A0134', undefined)
exports.TableTopPitchAngle = new Element(805962048, 'TableTopPitchAngle', 'FL', '1', '300A0140', undefined)
exports.TableTopPitchRotationDirection = new Element(805962050, 'TableTopPitchRotationDirection', 'CS', '1', '300A0142', undefined)
exports.TableTopRollAngle = new Element(805962052, 'TableTopRollAngle', 'FL', '1', '300A0144', undefined)
exports.TableTopRollRotationDirection = new Element(805962054, 'TableTopRollRotationDirection', 'CS', '1', '300A0146', undefined)
exports.HeadFixationAngle = new Element(805962056, 'HeadFixationAngle', 'FL', '1', '300A0148', undefined)
exports.GantryPitchAngle = new Element(805962058, 'GantryPitchAngle', 'FL', '1', '300A014A', undefined)
exports.GantryPitchRotationDirection = new Element(805962060, 'GantryPitchRotationDirection', 'CS', '1', '300A014C', undefined)
exports.GantryPitchAngleTolerance = new Element(805962062, 'GantryPitchAngleTolerance', 'FL', '1', '300A014E', undefined)
exports.PatientSetupSequence = new Element(805962112, 'PatientSetupSequence', 'SQ', '1', '300A0180', undefined)
exports.PatientSetupNumber = new Element(805962114, 'PatientSetupNumber', 'IS', '1', '300A0182', undefined)
exports.PatientSetupLabel = new Element(805962115, 'PatientSetupLabel', 'LO', '1', '300A0183', undefined)
exports.PatientAdditionalPosition = new Element(805962116, 'PatientAdditionalPosition', 'LO', '1', '300A0184', undefined)
exports.FixationDeviceSequence = new Element(805962128, 'FixationDeviceSequence', 'SQ', '1', '300A0190', undefined)
exports.FixationDeviceType = new Element(805962130, 'FixationDeviceType', 'CS', '1', '300A0192', undefined)
exports.FixationDeviceLabel = new Element(805962132, 'FixationDeviceLabel', 'SH', '1', '300A0194', undefined)
exports.FixationDeviceDescription = new Element(805962134, 'FixationDeviceDescription', 'ST', '1', '300A0196', undefined)
exports.FixationDevicePosition = new Element(805962136, 'FixationDevicePosition', 'SH', '1', '300A0198', undefined)
exports.FixationDevicePitchAngle = new Element(805962137, 'FixationDevicePitchAngle', 'FL', '1', '300A0199', undefined)
exports.FixationDeviceRollAngle = new Element(805962138, 'FixationDeviceRollAngle', 'FL', '1', '300A019A', undefined)
exports.ShieldingDeviceSequence = new Element(805962144, 'ShieldingDeviceSequence', 'SQ', '1', '300A01A0', undefined)
exports.ShieldingDeviceType = new Element(805962146, 'ShieldingDeviceType', 'CS', '1', '300A01A2', undefined)
exports.ShieldingDeviceLabel = new Element(805962148, 'ShieldingDeviceLabel', 'SH', '1', '300A01A4', undefined)
exports.ShieldingDeviceDescription = new Element(805962150, 'ShieldingDeviceDescription', 'ST', '1', '300A01A6', undefined)
exports.ShieldingDevicePosition = new Element(805962152, 'ShieldingDevicePosition', 'SH', '1', '300A01A8', undefined)
exports.SetupTechnique = new Element(805962160, 'SetupTechnique', 'CS', '1', '300A01B0', undefined)
exports.SetupTechniqueDescription = new Element(805962162, 'SetupTechniqueDescription', 'ST', '1', '300A01B2', undefined)
exports.SetupDeviceSequence = new Element(805962164, 'SetupDeviceSequence', 'SQ', '1', '300A01B4', undefined)
exports.SetupDeviceType = new Element(805962166, 'SetupDeviceType', 'CS', '1', '300A01B6', undefined)
exports.SetupDeviceLabel = new Element(805962168, 'SetupDeviceLabel', 'SH', '1', '300A01B8', undefined)
exports.SetupDeviceDescription = new Element(805962170, 'SetupDeviceDescription', 'ST', '1', '300A01BA', undefined)
exports.SetupDeviceParameter = new Element(805962172, 'SetupDeviceParameter', 'DS', '1', '300A01BC', undefined)
exports.SetupReferenceDescription = new Element(805962192, 'SetupReferenceDescription', 'ST', '1', '300A01D0', undefined)
exports.TableTopVerticalSetupDisplacement = new Element(805962194, 'TableTopVerticalSetupDisplacement', 'DS', '1', '300A01D2', undefined)
exports.TableTopLongitudinalSetupDisplacement = new Element(805962196, 'TableTopLongitudinalSetupDisplacement', 'DS', '1', '300A01D4', undefined)
exports.TableTopLateralSetupDisplacement = new Element(805962198, 'TableTopLateralSetupDisplacement', 'DS', '1', '300A01D6', undefined)
exports.BrachyTreatmentTechnique = new Element(805962240, 'BrachyTreatmentTechnique', 'CS', '1', '300A0200', undefined)
exports.BrachyTreatmentType = new Element(805962242, 'BrachyTreatmentType', 'CS', '1', '300A0202', undefined)
exports.TreatmentMachineSequence = new Element(805962246, 'TreatmentMachineSequence', 'SQ', '1', '300A0206', undefined)
exports.SourceSequence = new Element(805962256, 'SourceSequence', 'SQ', '1', '300A0210', undefined)
exports.SourceNumber = new Element(805962258, 'SourceNumber', 'IS', '1', '300A0212', undefined)
exports.SourceType = new Element(805962260, 'SourceType', 'CS', '1', '300A0214', undefined)
exports.SourceManufacturer = new Element(805962262, 'SourceManufacturer', 'LO', '1', '300A0216', undefined)
exports.ActiveSourceDiameter = new Element(805962264, 'ActiveSourceDiameter', 'DS', '1', '300A0218', undefined)
exports.ActiveSourceLength = new Element(805962266, 'ActiveSourceLength', 'DS', '1', '300A021A', undefined)
exports.SourceModelID = new Element(805962267, 'SourceModelID', 'SH', '1', '300A021B', undefined)
exports.SourceDescription = new Element(805962268, 'SourceDescription', 'LO', '1', '300A021C', undefined)
exports.SourceEncapsulationNominalThickness = new Element(805962274, 'SourceEncapsulationNominalThickness', 'DS', '1', '300A0222', undefined)
exports.SourceEncapsulationNominalTransmission = new Element(805962276, 'SourceEncapsulationNominalTransmission', 'DS', '1', '300A0224', undefined)
exports.SourceIsotopeName = new Element(805962278, 'SourceIsotopeName', 'LO', '1', '300A0226', undefined)
exports.SourceIsotopeHalfLife = new Element(805962280, 'SourceIsotopeHalfLife', 'DS', '1', '300A0228', undefined)
exports.SourceStrengthUnits = new Element(805962281, 'SourceStrengthUnits', 'CS', '1', '300A0229', undefined)
exports.ReferenceAirKermaRate = new Element(805962282, 'ReferenceAirKermaRate', 'DS', '1', '300A022A', undefined)
exports.SourceStrength = new Element(805962283, 'SourceStrength', 'DS', '1', '300A022B', undefined)
exports.SourceStrengthReferenceDate = new Element(805962284, 'SourceStrengthReferenceDate', 'DA', '1', '300A022C', undefined)
exports.SourceStrengthReferenceTime = new Element(805962286, 'SourceStrengthReferenceTime', 'TM', '1', '300A022E', undefined)
exports.ApplicationSetupSequence = new Element(805962288, 'ApplicationSetupSequence', 'SQ', '1', '300A0230', undefined)
exports.ApplicationSetupType = new Element(805962290, 'ApplicationSetupType', 'CS', '1', '300A0232', undefined)
exports.ApplicationSetupNumber = new Element(805962292, 'ApplicationSetupNumber', 'IS', '1', '300A0234', undefined)
exports.ApplicationSetupName = new Element(805962294, 'ApplicationSetupName', 'LO', '1', '300A0236', undefined)
exports.ApplicationSetupManufacturer = new Element(805962296, 'ApplicationSetupManufacturer', 'LO', '1', '300A0238', undefined)
exports.TemplateNumber = new Element(805962304, 'TemplateNumber', 'IS', '1', '300A0240', undefined)
exports.TemplateType = new Element(805962306, 'TemplateType', 'SH', '1', '300A0242', undefined)
exports.TemplateName = new Element(805962308, 'TemplateName', 'LO', '1', '300A0244', undefined)
exports.TotalReferenceAirKerma = new Element(805962320, 'TotalReferenceAirKerma', 'DS', '1', '300A0250', undefined)
exports.BrachyAccessoryDeviceSequence = new Element(805962336, 'BrachyAccessoryDeviceSequence', 'SQ', '1', '300A0260', undefined)
exports.BrachyAccessoryDeviceNumber = new Element(805962338, 'BrachyAccessoryDeviceNumber', 'IS', '1', '300A0262', undefined)
exports.BrachyAccessoryDeviceID = new Element(805962339, 'BrachyAccessoryDeviceID', 'SH', '1', '300A0263', undefined)
exports.BrachyAccessoryDeviceType = new Element(805962340, 'BrachyAccessoryDeviceType', 'CS', '1', '300A0264', undefined)
exports.BrachyAccessoryDeviceName = new Element(805962342, 'BrachyAccessoryDeviceName', 'LO', '1', '300A0266', undefined)
exports.BrachyAccessoryDeviceNominalThickness = new Element(805962346, 'BrachyAccessoryDeviceNominalThickness', 'DS', '1', '300A026A', undefined)
exports.BrachyAccessoryDeviceNominalTransmission = new Element(805962348, 'BrachyAccessoryDeviceNominalTransmission', 'DS', '1', '300A026C', undefined)
exports.ChannelSequence = new Element(805962368, 'ChannelSequence', 'SQ', '1', '300A0280', undefined)
exports.ChannelNumber = new Element(805962370, 'ChannelNumber', 'IS', '1', '300A0282', undefined)
exports.ChannelLength = new Element(805962372, 'ChannelLength', 'DS', '1', '300A0284', undefined)
exports.ChannelTotalTime = new Element(805962374, 'ChannelTotalTime', 'DS', '1', '300A0286', undefined)
exports.SourceMovementType = new Element(805962376, 'SourceMovementType', 'CS', '1', '300A0288', undefined)
exports.NumberOfPulses = new Element(805962378, 'NumberOfPulses', 'IS', '1', '300A028A', undefined)
exports.PulseRepetitionInterval = new Element(805962380, 'PulseRepetitionInterval', 'DS', '1', '300A028C', undefined)
exports.SourceApplicatorNumber = new Element(805962384, 'SourceApplicatorNumber', 'IS', '1', '300A0290', undefined)
exports.SourceApplicatorID = new Element(805962385, 'SourceApplicatorID', 'SH', '1', '300A0291', undefined)
exports.SourceApplicatorType = new Element(805962386, 'SourceApplicatorType', 'CS', '1', '300A0292', undefined)
exports.SourceApplicatorName = new Element(805962388, 'SourceApplicatorName', 'LO', '1', '300A0294', undefined)
exports.SourceApplicatorLength = new Element(805962390, 'SourceApplicatorLength', 'DS', '1', '300A0296', undefined)
exports.SourceApplicatorManufacturer = new Element(805962392, 'SourceApplicatorManufacturer', 'LO', '1', '300A0298', undefined)
exports.SourceApplicatorWallNominalThickness = new Element(805962396, 'SourceApplicatorWallNominalThickness', 'DS', '1', '300A029C', undefined)
exports.SourceApplicatorWallNominalTransmission = new Element(805962398, 'SourceApplicatorWallNominalTransmission', 'DS', '1', '300A029E', undefined)
exports.SourceApplicatorStepSize = new Element(805962400, 'SourceApplicatorStepSize', 'DS', '1', '300A02A0', undefined)
exports.TransferTubeNumber = new Element(805962402, 'TransferTubeNumber', 'IS', '1', '300A02A2', undefined)
exports.TransferTubeLength = new Element(805962404, 'TransferTubeLength', 'DS', '1', '300A02A4', undefined)
exports.ChannelShieldSequence = new Element(805962416, 'ChannelShieldSequence', 'SQ', '1', '300A02B0', undefined)
exports.ChannelShieldNumber = new Element(805962418, 'ChannelShieldNumber', 'IS', '1', '300A02B2', undefined)
exports.ChannelShieldID = new Element(805962419, 'ChannelShieldID', 'SH', '1', '300A02B3', undefined)
exports.ChannelShieldName = new Element(805962420, 'ChannelShieldName', 'LO', '1', '300A02B4', undefined)
exports.ChannelShieldNominalThickness = new Element(805962424, 'ChannelShieldNominalThickness', 'DS', '1', '300A02B8', undefined)
exports.ChannelShieldNominalTransmission = new Element(805962426, 'ChannelShieldNominalTransmission', 'DS', '1', '300A02BA', undefined)
exports.FinalCumulativeTimeWeight = new Element(805962440, 'FinalCumulativeTimeWeight', 'DS', '1', '300A02C8', undefined)
exports.BrachyControlPointSequence = new Element(805962448, 'BrachyControlPointSequence', 'SQ', '1', '300A02D0', undefined)
exports.ControlPointRelativePosition = new Element(805962450, 'ControlPointRelativePosition', 'DS', '1', '300A02D2', undefined)
exports.ControlPoint3DPosition = new Element(805962452, 'ControlPoint3DPosition', 'DS', '3', '300A02D4', undefined)
exports.CumulativeTimeWeight = new Element(805962454, 'CumulativeTimeWeight', 'DS', '1', '300A02D6', undefined)
exports.CompensatorDivergence = new Element(805962464, 'CompensatorDivergence', 'CS', '1', '300A02E0', undefined)
exports.CompensatorMountingPosition = new Element(805962465, 'CompensatorMountingPosition', 'CS', '1', '300A02E1', undefined)
exports.SourceToCompensatorDistance = new Element(805962466, 'SourceToCompensatorDistance', 'DS', '1-n', '300A02E2', undefined)
exports.TotalCompensatorTrayWaterEquivalentThickness = new Element(805962467, 'TotalCompensatorTrayWaterEquivalentThickness', 'FL', '1', '300A02E3', undefined)
exports.IsocenterToCompensatorTrayDistance = new Element(805962468, 'IsocenterToCompensatorTrayDistance', 'FL', '1', '300A02E4', undefined)
exports.CompensatorColumnOffset = new Element(805962469, 'CompensatorColumnOffset', 'FL', '1', '300A02E5', undefined)
exports.IsocenterToCompensatorDistances = new Element(805962470, 'IsocenterToCompensatorDistances', 'FL', '1-n', '300A02E6', undefined)
exports.CompensatorRelativeStoppingPowerRatio = new Element(805962471, 'CompensatorRelativeStoppingPowerRatio', 'FL', '1', '300A02E7', undefined)
exports.CompensatorMillingToolDiameter = new Element(805962472, 'CompensatorMillingToolDiameter', 'FL', '1', '300A02E8', undefined)
exports.IonRangeCompensatorSequence = new Element(805962474, 'IonRangeCompensatorSequence', 'SQ', '1', '300A02EA', undefined)
exports.CompensatorDescription = new Element(805962475, 'CompensatorDescription', 'LT', '1', '300A02EB', undefined)
exports.RadiationMassNumber = new Element(805962498, 'RadiationMassNumber', 'IS', '1', '300A0302', undefined)
exports.RadiationAtomicNumber = new Element(805962500, 'RadiationAtomicNumber', 'IS', '1', '300A0304', undefined)
exports.RadiationChargeState = new Element(805962502, 'RadiationChargeState', 'SS', '1', '300A0306', undefined)
exports.ScanMode = new Element(805962504, 'ScanMode', 'CS', '1', '300A0308', undefined)
exports.VirtualSourceAxisDistances = new Element(805962506, 'VirtualSourceAxisDistances', 'FL', '2', '300A030A', undefined)
exports.SnoutSequence = new Element(805962508, 'SnoutSequence', 'SQ', '1', '300A030C', undefined)
exports.SnoutPosition = new Element(805962509, 'SnoutPosition', 'FL', '1', '300A030D', undefined)
exports.SnoutID = new Element(805962511, 'SnoutID', 'SH', '1', '300A030F', undefined)
exports.NumberOfRangeShifters = new Element(805962514, 'NumberOfRangeShifters', 'IS', '1', '300A0312', undefined)
exports.RangeShifterSequence = new Element(805962516, 'RangeShifterSequence', 'SQ', '1', '300A0314', undefined)
exports.RangeShifterNumber = new Element(805962518, 'RangeShifterNumber', 'IS', '1', '300A0316', undefined)
exports.RangeShifterID = new Element(805962520, 'RangeShifterID', 'SH', '1', '300A0318', undefined)
exports.RangeShifterType = new Element(805962528, 'RangeShifterType', 'CS', '1', '300A0320', undefined)
exports.RangeShifterDescription = new Element(805962530, 'RangeShifterDescription', 'LO', '1', '300A0322', undefined)
exports.NumberOfLateralSpreadingDevices = new Element(805962544, 'NumberOfLateralSpreadingDevices', 'IS', '1', '300A0330', undefined)
exports.LateralSpreadingDeviceSequence = new Element(805962546, 'LateralSpreadingDeviceSequence', 'SQ', '1', '300A0332', undefined)
exports.LateralSpreadingDeviceNumber = new Element(805962548, 'LateralSpreadingDeviceNumber', 'IS', '1', '300A0334', undefined)
exports.LateralSpreadingDeviceID = new Element(805962550, 'LateralSpreadingDeviceID', 'SH', '1', '300A0336', undefined)
exports.LateralSpreadingDeviceType = new Element(805962552, 'LateralSpreadingDeviceType', 'CS', '1', '300A0338', undefined)
exports.LateralSpreadingDeviceDescription = new Element(805962554, 'LateralSpreadingDeviceDescription', 'LO', '1', '300A033A', undefined)
exports.LateralSpreadingDeviceWaterEquivalentThickness = new Element(805962556, 'LateralSpreadingDeviceWaterEquivalentThickness', 'FL', '1', '300A033C', undefined)
exports.NumberOfRangeModulators = new Element(805962560, 'NumberOfRangeModulators', 'IS', '1', '300A0340', undefined)
exports.RangeModulatorSequence = new Element(805962562, 'RangeModulatorSequence', 'SQ', '1', '300A0342', undefined)
exports.RangeModulatorNumber = new Element(805962564, 'RangeModulatorNumber', 'IS', '1', '300A0344', undefined)
exports.RangeModulatorID = new Element(805962566, 'RangeModulatorID', 'SH', '1', '300A0346', undefined)
exports.RangeModulatorType = new Element(805962568, 'RangeModulatorType', 'CS', '1', '300A0348', undefined)
exports.RangeModulatorDescription = new Element(805962570, 'RangeModulatorDescription', 'LO', '1', '300A034A', undefined)
exports.BeamCurrentModulationID = new Element(805962572, 'BeamCurrentModulationID', 'SH', '1', '300A034C', undefined)
exports.PatientSupportType = new Element(805962576, 'PatientSupportType', 'CS', '1', '300A0350', undefined)
exports.PatientSupportID = new Element(805962578, 'PatientSupportID', 'SH', '1', '300A0352', undefined)
exports.PatientSupportAccessoryCode = new Element(805962580, 'PatientSupportAccessoryCode', 'LO', '1', '300A0354', undefined)
exports.FixationLightAzimuthalAngle = new Element(805962582, 'FixationLightAzimuthalAngle', 'FL', '1', '300A0356', undefined)
exports.FixationLightPolarAngle = new Element(805962584, 'FixationLightPolarAngle', 'FL', '1', '300A0358', undefined)
exports.MetersetRate = new Element(805962586, 'MetersetRate', 'FL', '1', '300A035A', undefined)
exports.RangeShifterSettingsSequence = new Element(805962592, 'RangeShifterSettingsSequence', 'SQ', '1', '300A0360', undefined)
exports.RangeShifterSetting = new Element(805962594, 'RangeShifterSetting', 'LO', '1', '300A0362', undefined)
exports.IsocenterToRangeShifterDistance = new Element(805962596, 'IsocenterToRangeShifterDistance', 'FL', '1', '300A0364', undefined)
exports.RangeShifterWaterEquivalentThickness = new Element(805962598, 'RangeShifterWaterEquivalentThickness', 'FL', '1', '300A0366', undefined)
exports.LateralSpreadingDeviceSettingsSequence = new Element(805962608, 'LateralSpreadingDeviceSettingsSequence', 'SQ', '1', '300A0370', undefined)
exports.LateralSpreadingDeviceSetting = new Element(805962610, 'LateralSpreadingDeviceSetting', 'LO', '1', '300A0372', undefined)
exports.IsocenterToLateralSpreadingDeviceDistance = new Element(805962612, 'IsocenterToLateralSpreadingDeviceDistance', 'FL', '1', '300A0374', undefined)
exports.RangeModulatorSettingsSequence = new Element(805962624, 'RangeModulatorSettingsSequence', 'SQ', '1', '300A0380', undefined)
exports.RangeModulatorGatingStartValue = new Element(805962626, 'RangeModulatorGatingStartValue', 'FL', '1', '300A0382', undefined)
exports.RangeModulatorGatingStopValue = new Element(805962628, 'RangeModulatorGatingStopValue', 'FL', '1', '300A0384', undefined)
exports.RangeModulatorGatingStartWaterEquivalentThickness = new Element(805962630, 'RangeModulatorGatingStartWaterEquivalentThickness', 'FL', '1', '300A0386', undefined)
exports.RangeModulatorGatingStopWaterEquivalentThickness = new Element(805962632, 'RangeModulatorGatingStopWaterEquivalentThickness', 'FL', '1', '300A0388', undefined)
exports.IsocenterToRangeModulatorDistance = new Element(805962634, 'IsocenterToRangeModulatorDistance', 'FL', '1', '300A038A', undefined)
exports.ScanSpotTuneID = new Element(805962640, 'ScanSpotTuneID', 'SH', '1', '300A0390', undefined)
exports.NumberOfScanSpotPositions = new Element(805962642, 'NumberOfScanSpotPositions', 'IS', '1', '300A0392', undefined)
exports.ScanSpotPositionMap = new Element(805962644, 'ScanSpotPositionMap', 'FL', '1-n', '300A0394', undefined)
exports.ScanSpotMetersetWeights = new Element(805962646, 'ScanSpotMetersetWeights', 'FL', '1-n', '300A0396', undefined)
exports.ScanningSpotSize = new Element(805962648, 'ScanningSpotSize', 'FL', '2', '300A0398', undefined)
exports.NumberOfPaintings = new Element(805962650, 'NumberOfPaintings', 'IS', '1', '300A039A', undefined)
exports.IonToleranceTableSequence = new Element(805962656, 'IonToleranceTableSequence', 'SQ', '1', '300A03A0', undefined)
exports.IonBeamSequence = new Element(805962658, 'IonBeamSequence', 'SQ', '1', '300A03A2', undefined)
exports.IonBeamLimitingDeviceSequence = new Element(805962660, 'IonBeamLimitingDeviceSequence', 'SQ', '1', '300A03A4', undefined)
exports.IonBlockSequence = new Element(805962662, 'IonBlockSequence', 'SQ', '1', '300A03A6', undefined)
exports.IonControlPointSequence = new Element(805962664, 'IonControlPointSequence', 'SQ', '1', '300A03A8', undefined)
exports.IonWedgeSequence = new Element(805962666, 'IonWedgeSequence', 'SQ', '1', '300A03AA', undefined)
exports.IonWedgePositionSequence = new Element(805962668, 'IonWedgePositionSequence', 'SQ', '1', '300A03AC', undefined)
exports.ReferencedSetupImageSequence = new Element(805962753, 'ReferencedSetupImageSequence', 'SQ', '1', '300A0401', undefined)
exports.SetupImageComment = new Element(805962754, 'SetupImageComment', 'ST', '1', '300A0402', undefined)
exports.MotionSynchronizationSequence = new Element(805962768, 'MotionSynchronizationSequence', 'SQ', '1', '300A0410', undefined)
exports.ControlPointOrientation = new Element(805962770, 'ControlPointOrientation', 'FL', '3', '300A0412', undefined)
exports.GeneralAccessorySequence = new Element(805962784, 'GeneralAccessorySequence', 'SQ', '1', '300A0420', undefined)
exports.GeneralAccessoryID = new Element(805962785, 'GeneralAccessoryID', 'SH', '1', '300A0421', undefined)
exports.GeneralAccessoryDescription = new Element(805962786, 'GeneralAccessoryDescription', 'ST', '1', '300A0422', undefined)
exports.GeneralAccessoryType = new Element(805962787, 'GeneralAccessoryType', 'CS', '1', '300A0423', undefined)
exports.GeneralAccessoryNumber = new Element(805962788, 'GeneralAccessoryNumber', 'IS', '1', '300A0424', undefined)
exports.SourceToGeneralAccessoryDistance = new Element(805962789, 'SourceToGeneralAccessoryDistance', 'FL', '1', '300A0425', undefined)
exports.ApplicatorGeometrySequence = new Element(805962801, 'ApplicatorGeometrySequence', 'SQ', '1', '300A0431', undefined)
exports.ApplicatorApertureShape = new Element(805962802, 'ApplicatorApertureShape', 'CS', '1', '300A0432', undefined)
exports.ApplicatorOpening = new Element(805962803, 'ApplicatorOpening', 'FL', '1', '300A0433', undefined)
exports.ApplicatorOpeningX = new Element(805962804, 'ApplicatorOpeningX', 'FL', '1', '300A0434', undefined)
exports.ApplicatorOpeningY = new Element(805962805, 'ApplicatorOpeningY', 'FL', '1', '300A0435', undefined)
exports.SourceToApplicatorMountingPositionDistance = new Element(805962806, 'SourceToApplicatorMountingPositionDistance', 'FL', '1', '300A0436', undefined)
exports.ReferencedRTPlanSequence = new Element(806092802, 'ReferencedRTPlanSequence', 'SQ', '1', '300C0002', undefined)
exports.ReferencedBeamSequence = new Element(806092804, 'ReferencedBeamSequence', 'SQ', '1', '300C0004', undefined)
exports.ReferencedBeamNumber = new Element(806092806, 'ReferencedBeamNumber', 'IS', '1', '300C0006', undefined)
exports.ReferencedReferenceImageNumber = new Element(806092807, 'ReferencedReferenceImageNumber', 'IS', '1', '300C0007', undefined)
exports.StartCumulativeMetersetWeight = new Element(806092808, 'StartCumulativeMetersetWeight', 'DS', '1', '300C0008', undefined)
exports.EndCumulativeMetersetWeight = new Element(806092809, 'EndCumulativeMetersetWeight', 'DS', '1', '300C0009', undefined)
exports.ReferencedBrachyApplicationSetupSequence = new Element(806092810, 'ReferencedBrachyApplicationSetupSequence', 'SQ', '1', '300C000A', undefined)
exports.ReferencedBrachyApplicationSetupNumber = new Element(806092812, 'ReferencedBrachyApplicationSetupNumber', 'IS', '1', '300C000C', undefined)
exports.ReferencedSourceNumber = new Element(806092814, 'ReferencedSourceNumber', 'IS', '1', '300C000E', undefined)
exports.ReferencedFractionGroupSequence = new Element(806092832, 'ReferencedFractionGroupSequence', 'SQ', '1', '300C0020', undefined)
exports.ReferencedFractionGroupNumber = new Element(806092834, 'ReferencedFractionGroupNumber', 'IS', '1', '300C0022', undefined)
exports.ReferencedVerificationImageSequence = new Element(806092864, 'ReferencedVerificationImageSequence', 'SQ', '1', '300C0040', undefined)
exports.ReferencedReferenceImageSequence = new Element(806092866, 'ReferencedReferenceImageSequence', 'SQ', '1', '300C0042', undefined)
exports.ReferencedDoseReferenceSequence = new Element(806092880, 'ReferencedDoseReferenceSequence', 'SQ', '1', '300C0050', undefined)
exports.ReferencedDoseReferenceNumber = new Element(806092881, 'ReferencedDoseReferenceNumber', 'IS', '1', '300C0051', undefined)
exports.BrachyReferencedDoseReferenceSequence = new Element(806092885, 'BrachyReferencedDoseReferenceSequence', 'SQ', '1', '300C0055', undefined)
exports.ReferencedStructureSetSequence = new Element(806092896, 'ReferencedStructureSetSequence', 'SQ', '1', '300C0060', undefined)
exports.ReferencedPatientSetupNumber = new Element(806092906, 'ReferencedPatientSetupNumber', 'IS', '1', '300C006A', undefined)
exports.ReferencedDoseSequence = new Element(806092928, 'ReferencedDoseSequence', 'SQ', '1', '300C0080', undefined)
exports.ReferencedToleranceTableNumber = new Element(806092960, 'ReferencedToleranceTableNumber', 'IS', '1', '300C00A0', undefined)
exports.ReferencedBolusSequence = new Element(806092976, 'ReferencedBolusSequence', 'SQ', '1', '300C00B0', undefined)
exports.ReferencedWedgeNumber = new Element(806092992, 'ReferencedWedgeNumber', 'IS', '1', '300C00C0', undefined)
exports.ReferencedCompensatorNumber = new Element(806093008, 'ReferencedCompensatorNumber', 'IS', '1', '300C00D0', undefined)
exports.ReferencedBlockNumber = new Element(806093024, 'ReferencedBlockNumber', 'IS', '1', '300C00E0', undefined)
exports.ReferencedControlPointIndex = new Element(806093040, 'ReferencedControlPointIndex', 'IS', '1', '300C00F0', undefined)
exports.ReferencedControlPointSequence = new Element(806093042, 'ReferencedControlPointSequence', 'SQ', '1', '300C00F2', undefined)
exports.ReferencedStartControlPointIndex = new Element(806093044, 'ReferencedStartControlPointIndex', 'IS', '1', '300C00F4', undefined)
exports.ReferencedStopControlPointIndex = new Element(806093046, 'ReferencedStopControlPointIndex', 'IS', '1', '300C00F6', undefined)
exports.ReferencedRangeShifterNumber = new Element(806093056, 'ReferencedRangeShifterNumber', 'IS', '1', '300C0100', undefined)
exports.ReferencedLateralSpreadingDeviceNumber = new Element(806093058, 'ReferencedLateralSpreadingDeviceNumber', 'IS', '1', '300C0102', undefined)
exports.ReferencedRangeModulatorNumber = new Element(806093060, 'ReferencedRangeModulatorNumber', 'IS', '1', '300C0104', undefined)
exports.ApprovalStatus = new Element(806223874, 'ApprovalStatus', 'CS', '1', '300E0002', undefined)
exports.ReviewDate = new Element(806223876, 'ReviewDate', 'DA', '1', '300E0004', undefined)
exports.ReviewTime = new Element(806223877, 'ReviewTime', 'TM', '1', '300E0005', undefined)
exports.ReviewerName = new Element(806223880, 'ReviewerName', 'PN', '1', '300E0008', undefined)
exports.Arbitrary = new Element(1073741840, 'Arbitrary', 'LT', '1', '40000010', true)
exports.TextComments = new Element(1073758208, 'TextComments', 'LT', '1', '40004000', true)
exports.ResultsID = new Element(1074266176, 'ResultsID', 'SH', '1', '40080040', true)
exports.ResultsIDIssuer = new Element(1074266178, 'ResultsIDIssuer', 'LO', '1', '40080042', true)
exports.ReferencedInterpretationSequence = new Element(1074266192, 'ReferencedInterpretationSequence', 'SQ', '1', '40080050', true)
exports.ReportProductionStatusTrial = new Element(1074266367, 'ReportProductionStatusTrial', 'CS', '1', '400800FF', true)
exports.InterpretationRecordedDate = new Element(1074266368, 'InterpretationRecordedDate', 'DA', '1', '40080100', true)
exports.InterpretationRecordedTime = new Element(1074266369, 'InterpretationRecordedTime', 'TM', '1', '40080101', true)
exports.InterpretationRecorder = new Element(1074266370, 'InterpretationRecorder', 'PN', '1', '40080102', true)
exports.ReferenceToRecordedSound = new Element(1074266371, 'ReferenceToRecordedSound', 'LO', '1', '40080103', true)
exports.InterpretationTranscriptionDate = new Element(1074266376, 'InterpretationTranscriptionDate', 'DA', '1', '40080108', true)
exports.InterpretationTranscriptionTime = new Element(1074266377, 'InterpretationTranscriptionTime', 'TM', '1', '40080109', true)
exports.InterpretationTranscriber = new Element(1074266378, 'InterpretationTranscriber', 'PN', '1', '4008010A', true)
exports.InterpretationText = new Element(1074266379, 'InterpretationText', 'ST', '1', '4008010B', true)
exports.InterpretationAuthor = new Element(1074266380, 'InterpretationAuthor', 'PN', '1', '4008010C', true)
exports.InterpretationApproverSequence = new Element(1074266385, 'InterpretationApproverSequence', 'SQ', '1', '40080111', true)
exports.InterpretationApprovalDate = new Element(1074266386, 'InterpretationApprovalDate', 'DA', '1', '40080112', true)
exports.InterpretationApprovalTime = new Element(1074266387, 'InterpretationApprovalTime', 'TM', '1', '40080113', true)
exports.PhysicianApprovingInterpretation = new Element(1074266388, 'PhysicianApprovingInterpretation', 'PN', '1', '40080114', true)
exports.InterpretationDiagnosisDescription = new Element(1074266389, 'InterpretationDiagnosisDescription', 'LT', '1', '40080115', true)
exports.InterpretationDiagnosisCodeSequence = new Element(1074266391, 'InterpretationDiagnosisCodeSequence', 'SQ', '1', '40080117', true)
exports.ResultsDistributionListSequence = new Element(1074266392, 'ResultsDistributionListSequence', 'SQ', '1', '40080118', true)
exports.DistributionName = new Element(1074266393, 'DistributionName', 'PN', '1', '40080119', true)
exports.DistributionAddress = new Element(1074266394, 'DistributionAddress', 'LO', '1', '4008011A', true)
exports.InterpretationID = new Element(1074266624, 'InterpretationID', 'SH', '1', '40080200', true)
exports.InterpretationIDIssuer = new Element(1074266626, 'InterpretationIDIssuer', 'LO', '1', '40080202', true)
exports.InterpretationTypeID = new Element(1074266640, 'InterpretationTypeID', 'CS', '1', '40080210', true)
exports.InterpretationStatusID = new Element(1074266642, 'InterpretationStatusID', 'CS', '1', '40080212', true)
exports.Impressions = new Element(1074266880, 'Impressions', 'ST', '1', '40080300', true)
exports.ResultsComments = new Element(1074282496, 'ResultsComments', 'ST', '1', '40084000', true)
exports.LowEnergyDetectors = new Element(1074790401, 'LowEnergyDetectors', 'CS', '1', '40100001', undefined)
exports.HighEnergyDetectors = new Element(1074790402, 'HighEnergyDetectors', 'CS', '1', '40100002', undefined)
exports.DetectorGeometrySequence = new Element(1074790404, 'DetectorGeometrySequence', 'SQ', '1', '40100004', undefined)
exports.ThreatROIVoxelSequence = new Element(1074794497, 'ThreatROIVoxelSequence', 'SQ', '1', '40101001', undefined)
exports.ThreatROIBase = new Element(1074794500, 'ThreatROIBase', 'FL', '3', '40101004', undefined)
exports.ThreatROIExtents = new Element(1074794501, 'ThreatROIExtents', 'FL', '3', '40101005', undefined)
exports.ThreatROIBitmap = new Element(1074794502, 'ThreatROIBitmap', 'OB', '1', '40101006', undefined)
exports.RouteSegmentID = new Element(1074794503, 'RouteSegmentID', 'SH', '1', '40101007', undefined)
exports.GantryType = new Element(1074794504, 'GantryType', 'CS', '1', '40101008', undefined)
exports.OOIOwnerType = new Element(1074794505, 'OOIOwnerType', 'CS', '1', '40101009', undefined)
exports.RouteSegmentSequence = new Element(1074794506, 'RouteSegmentSequence', 'SQ', '1', '4010100A', undefined)
exports.PotentialThreatObjectID = new Element(1074794512, 'PotentialThreatObjectID', 'US', '1', '40101010', undefined)
exports.ThreatSequence = new Element(1074794513, 'ThreatSequence', 'SQ', '1', '40101011', undefined)
exports.ThreatCategory = new Element(1074794514, 'ThreatCategory', 'CS', '1', '40101012', undefined)
exports.ThreatCategoryDescription = new Element(1074794515, 'ThreatCategoryDescription', 'LT', '1', '40101013', undefined)
exports.ATDAbilityAssessment = new Element(1074794516, 'ATDAbilityAssessment', 'CS', '1', '40101014', undefined)
exports.ATDAssessmentFlag = new Element(1074794517, 'ATDAssessmentFlag', 'CS', '1', '40101015', undefined)
exports.ATDAssessmentProbability = new Element(1074794518, 'ATDAssessmentProbability', 'FL', '1', '40101016', undefined)
exports.Mass = new Element(1074794519, 'Mass', 'FL', '1', '40101017', undefined)
exports.Density = new Element(1074794520, 'Density', 'FL', '1', '40101018', undefined)
exports.ZEffective = new Element(1074794521, 'ZEffective', 'FL', '1', '40101019', undefined)
exports.BoardingPassID = new Element(1074794522, 'BoardingPassID', 'SH', '1', '4010101A', undefined)
exports.CenterOfMass = new Element(1074794523, 'CenterOfMass', 'FL', '3', '4010101B', undefined)
exports.CenterOfPTO = new Element(1074794524, 'CenterOfPTO', 'FL', '3', '4010101C', undefined)
exports.BoundingPolygon = new Element(1074794525, 'BoundingPolygon', 'FL', '6-n', '4010101D', undefined)
exports.RouteSegmentStartLocationID = new Element(1074794526, 'RouteSegmentStartLocationID', 'SH', '1', '4010101E', undefined)
exports.RouteSegmentEndLocationID = new Element(1074794527, 'RouteSegmentEndLocationID', 'SH', '1', '4010101F', undefined)
exports.RouteSegmentLocationIDType = new Element(1074794528, 'RouteSegmentLocationIDType', 'CS', '1', '40101020', undefined)
exports.AbortReason = new Element(1074794529, 'AbortReason', 'CS', '1-n', '40101021', undefined)
exports.VolumeOfPTO = new Element(1074794531, 'VolumeOfPTO', 'FL', '1', '40101023', undefined)
exports.AbortFlag = new Element(1074794532, 'AbortFlag', 'CS', '1', '40101024', undefined)
exports.RouteSegmentStartTime = new Element(1074794533, 'RouteSegmentStartTime', 'DT', '1', '40101025', undefined)
exports.RouteSegmentEndTime = new Element(1074794534, 'RouteSegmentEndTime', 'DT', '1', '40101026', undefined)
exports.TDRType = new Element(1074794535, 'TDRType', 'CS', '1', '40101027', undefined)
exports.InternationalRouteSegment = new Element(1074794536, 'InternationalRouteSegment', 'CS', '1', '40101028', undefined)
exports.ThreatDetectionAlgorithmandVersion = new Element(1074794537, 'ThreatDetectionAlgorithmandVersion', 'LO', '1-n', '40101029', undefined)
exports.AssignedLocation = new Element(1074794538, 'AssignedLocation', 'SH', '1', '4010102A', undefined)
exports.AlarmDecisionTime = new Element(1074794539, 'AlarmDecisionTime', 'DT', '1', '4010102B', undefined)
exports.AlarmDecision = new Element(1074794545, 'AlarmDecision', 'CS', '1', '40101031', undefined)
exports.NumberOfTotalObjects = new Element(1074794547, 'NumberOfTotalObjects', 'US', '1', '40101033', undefined)
exports.NumberOfAlarmObjects = new Element(1074794548, 'NumberOfAlarmObjects', 'US', '1', '40101034', undefined)
exports.PTORepresentationSequence = new Element(1074794551, 'PTORepresentationSequence', 'SQ', '1', '40101037', undefined)
exports.ATDAssessmentSequence = new Element(1074794552, 'ATDAssessmentSequence', 'SQ', '1', '40101038', undefined)
exports.TIPType = new Element(1074794553, 'TIPType', 'CS', '1', '40101039', undefined)
exports.DICOSVersion = new Element(1074794554, 'DICOSVersion', 'CS', '1', '4010103A', undefined)
exports.OOIOwnerCreationTime = new Element(1074794561, 'OOIOwnerCreationTime', 'DT', '1', '40101041', undefined)
exports.OOIType = new Element(1074794562, 'OOIType', 'CS', '1', '40101042', undefined)
exports.OOISize = new Element(1074794563, 'OOISize', 'FL', '3', '40101043', undefined)
exports.AcquisitionStatus = new Element(1074794564, 'AcquisitionStatus', 'CS', '1', '40101044', undefined)
exports.BasisMaterialsCodeSequence = new Element(1074794565, 'BasisMaterialsCodeSequence', 'SQ', '1', '40101045', undefined)
exports.PhantomType = new Element(1074794566, 'PhantomType', 'CS', '1', '40101046', undefined)
exports.OOIOwnerSequence = new Element(1074794567, 'OOIOwnerSequence', 'SQ', '1', '40101047', undefined)
exports.ScanType = new Element(1074794568, 'ScanType', 'CS', '1', '40101048', undefined)
exports.ItineraryID = new Element(1074794577, 'ItineraryID', 'LO', '1', '40101051', undefined)
exports.ItineraryIDType = new Element(1074794578, 'ItineraryIDType', 'SH', '1', '40101052', undefined)
exports.ItineraryIDAssigningAuthority = new Element(1074794579, 'ItineraryIDAssigningAuthority', 'LO', '1', '40101053', undefined)
exports.RouteID = new Element(1074794580, 'RouteID', 'SH', '1', '40101054', undefined)
exports.RouteIDAssigningAuthority = new Element(1074794581, 'RouteIDAssigningAuthority', 'SH', '1', '40101055', undefined)
exports.InboundArrivalType = new Element(1074794582, 'InboundArrivalType', 'CS', '1', '40101056', undefined)
exports.CarrierID = new Element(1074794584, 'CarrierID', 'SH', '1', '40101058', undefined)
exports.CarrierIDAssigningAuthority = new Element(1074794585, 'CarrierIDAssigningAuthority', 'CS', '1', '40101059', undefined)
exports.SourceOrientation = new Element(1074794592, 'SourceOrientation', 'FL', '3', '40101060', undefined)
exports.SourcePosition = new Element(1074794593, 'SourcePosition', 'FL', '3', '40101061', undefined)
exports.BeltHeight = new Element(1074794594, 'BeltHeight', 'FL', '1', '40101062', undefined)
exports.AlgorithmRoutingCodeSequence = new Element(1074794596, 'AlgorithmRoutingCodeSequence', 'SQ', '1', '40101064', undefined)
exports.TransportClassification = new Element(1074794599, 'TransportClassification', 'CS', '1', '40101067', undefined)
exports.OOITypeDescriptor = new Element(1074794600, 'OOITypeDescriptor', 'LT', '1', '40101068', undefined)
exports.TotalProcessingTime = new Element(1074794601, 'TotalProcessingTime', 'FL', '1', '40101069', undefined)
exports.DetectorCalibrationData = new Element(1074794604, 'DetectorCalibrationData', 'OB', '1', '4010106C', undefined)
exports.AdditionalScreeningPerformed = new Element(1074794605, 'AdditionalScreeningPerformed', 'CS', '1', '4010106D', undefined)
exports.AdditionalInspectionSelectionCriteria = new Element(1074794606, 'AdditionalInspectionSelectionCriteria', 'CS', '1', '4010106E', undefined)
exports.AdditionalInspectionMethodSequence = new Element(1074794607, 'AdditionalInspectionMethodSequence', 'SQ', '1', '4010106F', undefined)
exports.AITDeviceType = new Element(1074794608, 'AITDeviceType', 'CS', '1', '40101070', undefined)
exports.QRMeasurementsSequence = new Element(1074794609, 'QRMeasurementsSequence', 'SQ', '1', '40101071', undefined)
exports.TargetMaterialSequence = new Element(1074794610, 'TargetMaterialSequence', 'SQ', '1', '40101072', undefined)
exports.SNRThreshold = new Element(1074794611, 'SNRThreshold', 'FD', '1', '40101073', undefined)
exports.ImageScaleRepresentation = new Element(1074794613, 'ImageScaleRepresentation', 'DS', '1', '40101075', undefined)
exports.ReferencedPTOSequence = new Element(1074794614, 'ReferencedPTOSequence', 'SQ', '1', '40101076', undefined)
exports.ReferencedTDRInstanceSequence = new Element(1074794615, 'ReferencedTDRInstanceSequence', 'SQ', '1', '40101077', undefined)
exports.PTOLocationDescription = new Element(1074794616, 'PTOLocationDescription', 'ST', '1', '40101078', undefined)
exports.AnomalyLocatorIndicatorSequence = new Element(1074794617, 'AnomalyLocatorIndicatorSequence', 'SQ', '1', '40101079', undefined)
exports.AnomalyLocatorIndicator = new Element(1074794618, 'AnomalyLocatorIndicator', 'FL', '3', '4010107A', undefined)
exports.PTORegionSequence = new Element(1074794619, 'PTORegionSequence', 'SQ', '1', '4010107B', undefined)
exports.InspectionSelectionCriteria = new Element(1074794620, 'InspectionSelectionCriteria', 'CS', '1', '4010107C', undefined)
exports.SecondaryInspectionMethodSequence = new Element(1074794621, 'SecondaryInspectionMethodSequence', 'SQ', '1', '4010107D', undefined)
exports.PRCSToRCSOrientation = new Element(1074794622, 'PRCSToRCSOrientation', 'DS', '6', '4010107E', undefined)
exports.MACParametersSequence = new Element(1342046209, 'MACParametersSequence', 'SQ', '1', '4FFE0001', undefined)
exports.CurveDimensions = new Element(1342177285, 'CurveDimensions', 'US', '1', '50xx0005', true)
exports.NumberOfPoints = new Element(1342177296, 'NumberOfPoints', 'US', '1', '50xx0010', true)
exports.TypeOfData = new Element(1342177312, 'TypeOfData', 'CS', '1', '50xx0020', true)
exports.CurveDescription = new Element(1342177314, 'CurveDescription', 'LO', '1', '50xx0022', true)
exports.AxisUnits = new Element(1342177328, 'AxisUnits', 'SH', '1-n', '50xx0030', true)
exports.AxisLabels = new Element(1342177344, 'AxisLabels', 'SH', '1-n', '50xx0040', true)
exports.DataValueRepresentation = new Element(1342177539, 'DataValueRepresentation', 'US', '1', '50xx0103', true)
exports.MinimumCoordinateValue = new Element(1342177540, 'MinimumCoordinateValue', 'US', '1-n', '50xx0104', true)
exports.MaximumCoordinateValue = new Element(1342177541, 'MaximumCoordinateValue', 'US', '1-n', '50xx0105', true)
exports.CurveRange = new Element(1342177542, 'CurveRange', 'SH', '1-n', '50xx0106', true)
exports.CurveDataDescriptor = new Element(1342177552, 'CurveDataDescriptor', 'US', '1-n', '50xx0110', true)
exports.CoordinateStartValue = new Element(1342177554, 'CoordinateStartValue', 'US', '1-n', '50xx0112', true)
exports.CoordinateStepValue = new Element(1342177556, 'CoordinateStepValue', 'US', '1-n', '50xx0114', true)
exports.CurveActivationLayer = new Element(1342181377, 'CurveActivationLayer', 'CS', '1', '50xx1001', true)
exports.AudioType = new Element(1342185472, 'AudioType', 'US', '1', '50xx2000', true)
exports.AudioSampleFormat = new Element(1342185474, 'AudioSampleFormat', 'US', '1', '50xx2002', true)
exports.NumberOfChannels = new Element(1342185476, 'NumberOfChannels', 'US', '1', '50xx2004', true)
exports.NumberOfSamples = new Element(1342185478, 'NumberOfSamples', 'UL', '1', '50xx2006', true)
exports.SampleRate = new Element(1342185480, 'SampleRate', 'UL', '1', '50xx2008', true)
exports.TotalTime = new Element(1342185482, 'TotalTime', 'UL', '1', '50xx200A', true)
exports.AudioSampleData = new Element(1342185484, 'AudioSampleData', 'OB or OW', '1', '50xx200C', true)
exports.AudioComments = new Element(1342185486, 'AudioComments', 'LT', '1', '50xx200E', true)
exports.CurveLabel = new Element(1342186752, 'CurveLabel', 'LO', '1', '50xx2500', true)
exports.CurveReferencedOverlaySequence = new Element(1342187008, 'CurveReferencedOverlaySequence', 'SQ', '1', '50xx2600', true)
exports.CurveReferencedOverlayGroup = new Element(1342187024, 'CurveReferencedOverlayGroup', 'US', '1', '50xx2610', true)
exports.CurveData = new Element(1342189568, 'CurveData', 'OB or OW', '1', '50xx3000', true)
exports.SharedFunctionalGroupsSequence = new Element(1375769129, 'SharedFunctionalGroupsSequence', 'SQ', '1', '52009229', undefined)
exports.PerFrameFunctionalGroupsSequence = new Element(1375769136, 'PerFrameFunctionalGroupsSequence', 'SQ', '1', '52009230', undefined)
exports.WaveformSequence = new Element(1409286400, 'WaveformSequence', 'SQ', '1', '54000100', undefined)
exports.ChannelMinimumValue = new Element(1409286416, 'ChannelMinimumValue', 'OB or OW', '1', '54000110', undefined)
exports.ChannelMaximumValue = new Element(1409286418, 'ChannelMaximumValue', 'OB or OW', '1', '54000112', undefined)
exports.WaveformBitsAllocated = new Element(1409290244, 'WaveformBitsAllocated', 'US', '1', '54001004', undefined)
exports.WaveformSampleInterpretation = new Element(1409290246, 'WaveformSampleInterpretation', 'CS', '1', '54001006', undefined)
exports.WaveformPaddingValue = new Element(1409290250, 'WaveformPaddingValue', 'OB or OW', '1', '5400100A', undefined)
exports.WaveformData = new Element(1409290256, 'WaveformData', 'OB or OW', '1', '54001010', undefined)
exports.FirstOrderPhaseCorrectionAngle = new Element(1442840592, 'FirstOrderPhaseCorrectionAngle', 'OF', '1', '56000010', undefined)
exports.SpectroscopyData = new Element(1442840608, 'SpectroscopyData', 'OF', '1', '56000020', undefined)
exports.OverlayRows = new Element(1610612752, 'OverlayRows', 'US', '1', '60xx0010', undefined)
exports.OverlayColumns = new Element(1610612753, 'OverlayColumns', 'US', '1', '60xx0011', undefined)
exports.OverlayPlanes = new Element(1610612754, 'OverlayPlanes', 'US', '1', '60xx0012', true)
exports.NumberOfFramesInOverlay = new Element(1610612757, 'NumberOfFramesInOverlay', 'IS', '1', '60xx0015', undefined)
exports.OverlayDescription = new Element(1610612770, 'OverlayDescription', 'LO', '1', '60xx0022', undefined)
exports.OverlayType = new Element(1610612800, 'OverlayType', 'CS', '1', '60xx0040', undefined)
exports.OverlaySubtype = new Element(1610612805, 'OverlaySubtype', 'LO', '1', '60xx0045', undefined)
exports.OverlayOrigin = new Element(1610612816, 'OverlayOrigin', 'SS', '2', '60xx0050', undefined)
exports.ImageFrameOrigin = new Element(1610612817, 'ImageFrameOrigin', 'US', '1', '60xx0051', undefined)
exports.OverlayPlaneOrigin = new Element(1610612818, 'OverlayPlaneOrigin', 'US', '1', '60xx0052', true)
exports.OverlayCompressionCode = new Element(1610612832, 'OverlayCompressionCode', 'CS', '1', '60xx0060', true)
exports.OverlayCompressionOriginator = new Element(1610612833, 'OverlayCompressionOriginator', 'SH', '1', '60xx0061', true)
exports.OverlayCompressionLabel = new Element(1610612834, 'OverlayCompressionLabel', 'SH', '1', '60xx0062', true)
exports.OverlayCompressionDescription = new Element(1610612835, 'OverlayCompressionDescription', 'CS', '1', '60xx0063', true)
exports.OverlayCompressionStepPointers = new Element(1610612838, 'OverlayCompressionStepPointers', 'AT', '1-n', '60xx0066', true)
exports.OverlayRepeatInterval = new Element(1610612840, 'OverlayRepeatInterval', 'US', '1', '60xx0068', true)
exports.OverlayBitsGrouped = new Element(1610612841, 'OverlayBitsGrouped', 'US', '1', '60xx0069', true)
exports.OverlayBitsAllocated = new Element(1610612992, 'OverlayBitsAllocated', 'US', '1', '60xx0100', undefined)
exports.OverlayBitPosition = new Element(1610612994, 'OverlayBitPosition', 'US', '1', '60xx0102', undefined)
exports.OverlayFormat = new Element(1610613008, 'OverlayFormat', 'CS', '1', '60xx0110', true)
exports.OverlayLocation = new Element(1610613248, 'OverlayLocation', 'US', '1', '60xx0200', true)
exports.OverlayCodeLabel = new Element(1610614784, 'OverlayCodeLabel', 'CS', '1-n', '60xx0800', true)
exports.OverlayNumberOfTables = new Element(1610614786, 'OverlayNumberOfTables', 'US', '1', '60xx0802', true)
exports.OverlayCodeTableLocation = new Element(1610614787, 'OverlayCodeTableLocation', 'AT', '1-n', '60xx0803', true)
exports.OverlayBitsForCodeWord = new Element(1610614788, 'OverlayBitsForCodeWord', 'US', '1', '60xx0804', true)
exports.OverlayActivationLayer = new Element(1610616833, 'OverlayActivationLayer', 'CS', '1', '60xx1001', undefined)
exports.OverlayDescriptorGray = new Element(1610617088, 'OverlayDescriptorGray', 'US', '1', '60xx1100', true)
exports.OverlayDescriptorRed = new Element(1610617089, 'OverlayDescriptorRed', 'US', '1', '60xx1101', true)
exports.OverlayDescriptorGreen = new Element(1610617090, 'OverlayDescriptorGreen', 'US', '1', '60xx1102', true)
exports.OverlayDescriptorBlue = new Element(1610617091, 'OverlayDescriptorBlue', 'US', '1', '60xx1103', true)
exports.OverlaysGray = new Element(1610617344, 'OverlaysGray', 'US', '1-n', '60xx1200', true)
exports.OverlaysRed = new Element(1610617345, 'OverlaysRed', 'US', '1-n', '60xx1201', true)
exports.OverlaysGreen = new Element(1610617346, 'OverlaysGreen', 'US', '1-n', '60xx1202', true)
exports.OverlaysBlue = new Element(1610617347, 'OverlaysBlue', 'US', '1-n', '60xx1203', true)
exports.ROIArea = new Element(1610617601, 'ROIArea', 'IS', '1', '60xx1301', undefined)
exports.ROIMean = new Element(1610617602, 'ROIMean', 'DS', '1', '60xx1302', undefined)
exports.ROIStandardDeviation = new Element(1610617603, 'ROIStandardDeviation', 'DS', '1', '60xx1303', undefined)
exports.OverlayLabel = new Element(1610618112, 'OverlayLabel', 'LO', '1', '60xx1500', undefined)
exports.OverlayData = new Element(1610625024, 'OverlayData', 'OB or OW', '1', '60xx3000', undefined)
exports.OverlayComments = new Element(1610629120, 'OverlayComments', 'LT', '1', '60xx4000', true)
exports.PixelData = new Element(2145386512, 'PixelData', 'OB or OW', '1', '7FE00010', undefined)
exports.CoefficientsSDVN = new Element(2145386528, 'CoefficientsSDVN', 'OW', '1', '7FE00020', true)
exports.CoefficientsSDHN = new Element(2145386544, 'CoefficientsSDHN', 'OW', '1', '7FE00030', true)
exports.CoefficientsSDDN = new Element(2145386560, 'CoefficientsSDDN', 'OW', '1', '7FE00040', true)
exports.VariablePixelData = new Element(2130706448, 'VariablePixelData', 'OB or OW', '1', '7Fxx0010', true)
exports.VariableNextDataGroup = new Element(2130706449, 'VariableNextDataGroup', 'US', '1', '7Fxx0011', true)
exports.VariableCoefficientsSDVN = new Element(2130706464, 'VariableCoefficientsSDVN', 'OW', '1', '7Fxx0020', true)
exports.VariableCoefficientsSDHN = new Element(2130706480, 'VariableCoefficientsSDHN', 'OW', '1', '7Fxx0030', true)
exports.VariableCoefficientsSDDN = new Element(2130706496, 'VariableCoefficientsSDDN', 'OW', '1', '7Fxx0040', true)
exports.DigitalSignaturesSequence = new Element(4294639610, 'DigitalSignaturesSequence', 'SQ', '1', 'FFFAFFFA', undefined)
exports.DataSetTrailingPadding = new Element(4294770684, 'DataSetTrailingPadding', 'OB', '1', 'FFFCFFFC', undefined)
exports.Item = new Element(4294893568, 'Item', 'undefined', '1', 'FFFEE000', undefined)
exports.ItemDelimitationItem = new Element(4294893581, 'ItemDelimitationItem', 'undefined', '1', 'FFFEE00D', undefined)
exports.SequenceDelimitationItem = new Element(4294893789, 'SequenceDelimitationItem', 'undefined', '1', 'FFFEE0DD', undefined)
_TAG_DICT =
  '00000000': exports.CommandGroupLength,
  '00000001': exports.CommandLengthToEnd,
  '00000002': exports.AffectedSOPClassUID,
  '00000003': exports.RequestedSOPClassUID,
  '00000010': exports.CommandRecognitionCode,
  '00000100': exports.CommandField,
  '00000110': exports.MessageID,
  '00000120': exports.MessageIDBeingRespondedTo,
  '00000200': exports.Initiator,
  '00000300': exports.Receiver,
  '00000400': exports.FindLocation,
  '00000600': exports.MoveDestination,
  '00000700': exports.Priority,
  '00000800': exports.CommandDataSetType,
  '00000850': exports.NumberOfMatches,
  '00000860': exports.ResponseSequenceNumber,
  '00000900': exports.Status,
  '00000901': exports.OffendingElement,
  '00000902': exports.ErrorComment,
  '00000903': exports.ErrorID,
  '00001000': exports.AffectedSOPInstanceUID,
  '00001001': exports.RequestedSOPInstanceUID,
  '00001002': exports.EventTypeID,
  '00001005': exports.AttributeIdentifierList,
  '00001008': exports.ActionTypeID,
  '00001020': exports.NumberOfRemainingSuboperations,
  '00001021': exports.NumberOfCompletedSuboperations,
  '00001022': exports.NumberOfFailedSuboperations,
  '00001023': exports.NumberOfWarningSuboperations,
  '00001030': exports.MoveOriginatorApplicationEntityTitle,
  '00001031': exports.MoveOriginatorMessageID,
  '00004000': exports.DialogReceiver,
  '00004010': exports.TerminalType,
  '00005010': exports.MessageSetID,
  '00005020': exports.EndMessageID,
  '00005110': exports.DisplayFormat,
  '00005120': exports.PagePositionID,
  '00005130': exports.TextFormatID,
  '00005140': exports.NormalReverse,
  '00005150': exports.AddGrayScale,
  '00005160': exports.Borders,
  '00005170': exports.Copies,
  '00005180': exports.CommandMagnificationType,
  '00005190': exports.Erase,
  '000051a0': exports.Print,
  '000051b0': exports.Overlays,
  '00020000': exports.FileMetaInformationGroupLength,
  '00020001': exports.FileMetaInformationVersion,
  '00020002': exports.MediaStorageSOPClassUID,
  '00020003': exports.MediaStorageSOPInstanceUID,
  '00020010': exports.TransferSyntaxUID,
  '00020012': exports.ImplementationClassUID,
  '00020013': exports.ImplementationVersionName,
  '00020016': exports.SourceApplicationEntityTitle,
  '00020017': exports.SendingApplicationEntityTitle,
  '00020018': exports.ReceivingApplicationEntityTitle,
  '00020100': exports.PrivateInformationCreatorUID,
  '00020102': exports.PrivateInformation,
  '00041130': exports.FileSetID,
  '00041141': exports.FileSetDescriptorFileID,
  '00041142': exports.SpecificCharacterSetOfFileSetDescriptorFile,
  '00041200': exports.OffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity,
  '00041202': exports.OffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity,
  '00041212': exports.FileSetConsistencyFlag,
  '00041220': exports.DirectoryRecordSequence,
  '00041400': exports.OffsetOfTheNextDirectoryRecord,
  '00041410': exports.RecordInUseFlag,
  '00041420': exports.OffsetOfReferencedLowerLevelDirectoryEntity,
  '00041430': exports.DirectoryRecordType,
  '00041432': exports.PrivateRecordUID,
  '00041500': exports.ReferencedFileID,
  '00041504': exports.MRDRDirectoryRecordOffset,
  '00041510': exports.ReferencedSOPClassUIDInFile,
  '00041511': exports.ReferencedSOPInstanceUIDInFile,
  '00041512': exports.ReferencedTransferSyntaxUIDInFile,
  '0004151a': exports.ReferencedRelatedGeneralSOPClassUIDInFile,
  '00041600': exports.NumberOfReferences,
  '00080001': exports.LengthToEnd,
  '00080005': exports.SpecificCharacterSet,
  '00080006': exports.LanguageCodeSequence,
  '00080008': exports.ImageType,
  '00080010': exports.RecognitionCode,
  '00080012': exports.InstanceCreationDate,
  '00080013': exports.InstanceCreationTime,
  '00080014': exports.InstanceCreatorUID,
  '00080015': exports.InstanceCoercionDateTime,
  '00080016': exports.SOPClassUID,
  '00080018': exports.SOPInstanceUID,
  '0008001a': exports.RelatedGeneralSOPClassUID,
  '0008001b': exports.OriginalSpecializedSOPClassUID,
  '00080020': exports.StudyDate,
  '00080021': exports.SeriesDate,
  '00080022': exports.AcquisitionDate,
  '00080023': exports.ContentDate,
  '00080024': exports.OverlayDate,
  '00080025': exports.CurveDate,
  '0008002a': exports.AcquisitionDateTime,
  '00080030': exports.StudyTime,
  '00080031': exports.SeriesTime,
  '00080032': exports.AcquisitionTime,
  '00080033': exports.ContentTime,
  '00080034': exports.OverlayTime,
  '00080035': exports.CurveTime,
  '00080040': exports.DataSetType,
  '00080041': exports.DataSetSubtype,
  '00080042': exports.NuclearMedicineSeriesType,
  '00080050': exports.AccessionNumber,
  '00080051': exports.IssuerOfAccessionNumberSequence,
  '00080052': exports.QueryRetrieveLevel,
  '00080053': exports.QueryRetrieveView,
  '00080054': exports.RetrieveAETitle,
  '00080056': exports.InstanceAvailability,
  '00080058': exports.FailedSOPInstanceUIDList,
  '00080060': exports.Modality,
  '00080061': exports.ModalitiesInStudy,
  '00080062': exports.SOPClassesInStudy,
  '00080064': exports.ConversionType,
  '00080068': exports.PresentationIntentType,
  '00080070': exports.Manufacturer,
  '00080080': exports.InstitutionName,
  '00080081': exports.InstitutionAddress,
  '00080082': exports.InstitutionCodeSequence,
  '00080090': exports.ReferringPhysicianName,
  '00080092': exports.ReferringPhysicianAddress,
  '00080094': exports.ReferringPhysicianTelephoneNumbers,
  '00080096': exports.ReferringPhysicianIdentificationSequence,
  '00080100': exports.CodeValue,
  '00080101': exports.ExtendedCodeValue,
  '00080102': exports.CodingSchemeDesignator,
  '00080103': exports.CodingSchemeVersion,
  '00080104': exports.CodeMeaning,
  '00080105': exports.MappingResource,
  '00080106': exports.ContextGroupVersion,
  '00080107': exports.ContextGroupLocalVersion,
  '00080108': exports.ExtendedCodeMeaning,
  '0008010b': exports.ContextGroupExtensionFlag,
  '0008010c': exports.CodingSchemeUID,
  '0008010d': exports.ContextGroupExtensionCreatorUID,
  '0008010f': exports.ContextIdentifier,
  '00080110': exports.CodingSchemeIdentificationSequence,
  '00080112': exports.CodingSchemeRegistry,
  '00080114': exports.CodingSchemeExternalID,
  '00080115': exports.CodingSchemeName,
  '00080116': exports.CodingSchemeResponsibleOrganization,
  '00080117': exports.ContextUID,
  '00080201': exports.TimezoneOffsetFromUTC,
  '00081000': exports.NetworkID,
  '00081010': exports.StationName,
  '00081030': exports.StudyDescription,
  '00081032': exports.ProcedureCodeSequence,
  '0008103e': exports.SeriesDescription,
  '0008103f': exports.SeriesDescriptionCodeSequence,
  '00081040': exports.InstitutionalDepartmentName,
  '00081048': exports.PhysiciansOfRecord,
  '00081049': exports.PhysiciansOfRecordIdentificationSequence,
  '00081050': exports.PerformingPhysicianName,
  '00081052': exports.PerformingPhysicianIdentificationSequence,
  '00081060': exports.NameOfPhysiciansReadingStudy,
  '00081062': exports.PhysiciansReadingStudyIdentificationSequence,
  '00081070': exports.OperatorsName,
  '00081072': exports.OperatorIdentificationSequence,
  '00081080': exports.AdmittingDiagnosesDescription,
  '00081084': exports.AdmittingDiagnosesCodeSequence,
  '00081090': exports.ManufacturerModelName,
  '00081100': exports.ReferencedResultsSequence,
  '00081110': exports.ReferencedStudySequence,
  '00081111': exports.ReferencedPerformedProcedureStepSequence,
  '00081115': exports.ReferencedSeriesSequence,
  '00081120': exports.ReferencedPatientSequence,
  '00081125': exports.ReferencedVisitSequence,
  '00081130': exports.ReferencedOverlaySequence,
  '00081134': exports.ReferencedStereometricInstanceSequence,
  '0008113a': exports.ReferencedWaveformSequence,
  '00081140': exports.ReferencedImageSequence,
  '00081145': exports.ReferencedCurveSequence,
  '0008114a': exports.ReferencedInstanceSequence,
  '0008114b': exports.ReferencedRealWorldValueMappingInstanceSequence,
  '00081150': exports.ReferencedSOPClassUID,
  '00081155': exports.ReferencedSOPInstanceUID,
  '0008115a': exports.SOPClassesSupported,
  '00081160': exports.ReferencedFrameNumber,
  '00081161': exports.SimpleFrameList,
  '00081162': exports.CalculatedFrameList,
  '00081163': exports.TimeRange,
  '00081164': exports.FrameExtractionSequence,
  '00081167': exports.MultiFrameSourceSOPInstanceUID,
  '00081190': exports.RetrieveURL,
  '00081195': exports.TransactionUID,
  '00081196': exports.WarningReason,
  '00081197': exports.FailureReason,
  '00081198': exports.FailedSOPSequence,
  '00081199': exports.ReferencedSOPSequence,
  '00081200': exports.StudiesContainingOtherReferencedInstancesSequence,
  '00081250': exports.RelatedSeriesSequence,
  '00082110': exports.LossyImageCompressionRetired,
  '00082111': exports.DerivationDescription,
  '00082112': exports.SourceImageSequence,
  '00082120': exports.StageName,
  '00082122': exports.StageNumber,
  '00082124': exports.NumberOfStages,
  '00082127': exports.ViewName,
  '00082128': exports.ViewNumber,
  '00082129': exports.NumberOfEventTimers,
  '0008212a': exports.NumberOfViewsInStage,
  '00082130': exports.EventElapsedTimes,
  '00082132': exports.EventTimerNames,
  '00082133': exports.EventTimerSequence,
  '00082134': exports.EventTimeOffset,
  '00082135': exports.EventCodeSequence,
  '00082142': exports.StartTrim,
  '00082143': exports.StopTrim,
  '00082144': exports.RecommendedDisplayFrameRate,
  '00082200': exports.TransducerPosition,
  '00082204': exports.TransducerOrientation,
  '00082208': exports.AnatomicStructure,
  '00082218': exports.AnatomicRegionSequence,
  '00082220': exports.AnatomicRegionModifierSequence,
  '00082228': exports.PrimaryAnatomicStructureSequence,
  '00082229': exports.AnatomicStructureSpaceOrRegionSequence,
  '00082230': exports.PrimaryAnatomicStructureModifierSequence,
  '00082240': exports.TransducerPositionSequence,
  '00082242': exports.TransducerPositionModifierSequence,
  '00082244': exports.TransducerOrientationSequence,
  '00082246': exports.TransducerOrientationModifierSequence,
  '00082251': exports.AnatomicStructureSpaceOrRegionCodeSequenceTrial,
  '00082253': exports.AnatomicPortalOfEntranceCodeSequenceTrial,
  '00082255': exports.AnatomicApproachDirectionCodeSequenceTrial,
  '00082256': exports.AnatomicPerspectiveDescriptionTrial,
  '00082257': exports.AnatomicPerspectiveCodeSequenceTrial,
  '00082258': exports.AnatomicLocationOfExaminingInstrumentDescriptionTrial,
  '00082259': exports.AnatomicLocationOfExaminingInstrumentCodeSequenceTrial,
  '0008225a': exports.AnatomicStructureSpaceOrRegionModifierCodeSequenceTrial,
  '0008225c': exports.OnAxisBackgroundAnatomicStructureCodeSequenceTrial,
  '00083001': exports.AlternateRepresentationSequence,
  '00083010': exports.IrradiationEventUID,
  '00083011': exports.SourceIrradiationEventSequence,
  '00083012': exports.RadiopharmaceuticalAdministrationEventUID,
  '00084000': exports.IdentifyingComments,
  '00089007': exports.FrameType,
  '00089092': exports.ReferencedImageEvidenceSequence,
  '00089121': exports.ReferencedRawDataSequence,
  '00089123': exports.CreatorVersionUID,
  '00089124': exports.DerivationImageSequence,
  '00089154': exports.SourceImageEvidenceSequence,
  '00089205': exports.PixelPresentation,
  '00089206': exports.VolumetricProperties,
  '00089207': exports.VolumeBasedCalculationTechnique,
  '00089208': exports.ComplexImageComponent,
  '00089209': exports.AcquisitionContrast,
  '00089215': exports.DerivationCodeSequence,
  '00089237': exports.ReferencedPresentationStateSequence,
  '00089410': exports.ReferencedOtherPlaneSequence,
  '00089458': exports.FrameDisplaySequence,
  '00089459': exports.RecommendedDisplayFrameRateInFloat,
  '00089460': exports.SkipFrameRangeFlag,
  '00100010': exports.PatientName,
  '00100020': exports.PatientID,
  '00100021': exports.IssuerOfPatientID,
  '00100022': exports.TypeOfPatientID,
  '00100024': exports.IssuerOfPatientIDQualifiersSequence,
  '00100030': exports.PatientBirthDate,
  '00100032': exports.PatientBirthTime,
  '00100040': exports.PatientSex,
  '00100050': exports.PatientInsurancePlanCodeSequence,
  '00100101': exports.PatientPrimaryLanguageCodeSequence,
  '00100102': exports.PatientPrimaryLanguageModifierCodeSequence,
  '00100200': exports.QualityControlSubject,
  '00100201': exports.QualityControlSubjectTypeCodeSequence,
  '00101000': exports.OtherPatientIDs,
  '00101001': exports.OtherPatientNames,
  '00101002': exports.OtherPatientIDsSequence,
  '00101005': exports.PatientBirthName,
  '00101010': exports.PatientAge,
  '00101020': exports.PatientSize,
  '00101021': exports.PatientSizeCodeSequence,
  '00101030': exports.PatientWeight,
  '00101040': exports.PatientAddress,
  '00101050': exports.InsurancePlanIdentification,
  '00101060': exports.PatientMotherBirthName,
  '00101080': exports.MilitaryRank,
  '00101081': exports.BranchOfService,
  '00101090': exports.MedicalRecordLocator,
  '00101100': exports.ReferencedPatientPhotoSequence,
  '00102000': exports.MedicalAlerts,
  '00102110': exports.Allergies,
  '00102150': exports.CountryOfResidence,
  '00102152': exports.RegionOfResidence,
  '00102154': exports.PatientTelephoneNumbers,
  '00102160': exports.EthnicGroup,
  '00102180': exports.Occupation,
  '001021a0': exports.SmokingStatus,
  '001021b0': exports.AdditionalPatientHistory,
  '001021c0': exports.PregnancyStatus,
  '001021d0': exports.LastMenstrualDate,
  '001021f0': exports.PatientReligiousPreference,
  '00102201': exports.PatientSpeciesDescription,
  '00102202': exports.PatientSpeciesCodeSequence,
  '00102203': exports.PatientSexNeutered,
  '00102210': exports.AnatomicalOrientationType,
  '00102292': exports.PatientBreedDescription,
  '00102293': exports.PatientBreedCodeSequence,
  '00102294': exports.BreedRegistrationSequence,
  '00102295': exports.BreedRegistrationNumber,
  '00102296': exports.BreedRegistryCodeSequence,
  '00102297': exports.ResponsiblePerson,
  '00102298': exports.ResponsiblePersonRole,
  '00102299': exports.ResponsibleOrganization,
  '00104000': exports.PatientComments,
  '00109431': exports.ExaminedBodyThickness,
  '00120010': exports.ClinicalTrialSponsorName,
  '00120020': exports.ClinicalTrialProtocolID,
  '00120021': exports.ClinicalTrialProtocolName,
  '00120030': exports.ClinicalTrialSiteID,
  '00120031': exports.ClinicalTrialSiteName,
  '00120040': exports.ClinicalTrialSubjectID,
  '00120042': exports.ClinicalTrialSubjectReadingID,
  '00120050': exports.ClinicalTrialTimePointID,
  '00120051': exports.ClinicalTrialTimePointDescription,
  '00120060': exports.ClinicalTrialCoordinatingCenterName,
  '00120062': exports.PatientIdentityRemoved,
  '00120063': exports.DeidentificationMethod,
  '00120064': exports.DeidentificationMethodCodeSequence,
  '00120071': exports.ClinicalTrialSeriesID,
  '00120072': exports.ClinicalTrialSeriesDescription,
  '00120081': exports.ClinicalTrialProtocolEthicsCommitteeName,
  '00120082': exports.ClinicalTrialProtocolEthicsCommitteeApprovalNumber,
  '00120083': exports.ConsentForClinicalTrialUseSequence,
  '00120084': exports.DistributionType,
  '00120085': exports.ConsentForDistributionFlag,
  '00140023': exports.CADFileFormat,
  '00140024': exports.ComponentReferenceSystem,
  '00140025': exports.ComponentManufacturingProcedure,
  '00140028': exports.ComponentManufacturer,
  '00140030': exports.MaterialThickness,
  '00140032': exports.MaterialPipeDiameter,
  '00140034': exports.MaterialIsolationDiameter,
  '00140042': exports.MaterialGrade,
  '00140044': exports.MaterialPropertiesDescription,
  '00140045': exports.MaterialPropertiesFileFormatRetired,
  '00140046': exports.MaterialNotes,
  '00140050': exports.ComponentShape,
  '00140052': exports.CurvatureType,
  '00140054': exports.OuterDiameter,
  '00140056': exports.InnerDiameter,
  '00141010': exports.ActualEnvironmentalConditions,
  '00141020': exports.ExpiryDate,
  '00141040': exports.EnvironmentalConditions,
  '00142002': exports.EvaluatorSequence,
  '00142004': exports.EvaluatorNumber,
  '00142006': exports.EvaluatorName,
  '00142008': exports.EvaluationAttempt,
  '00142012': exports.IndicationSequence,
  '00142014': exports.IndicationNumber,
  '00142016': exports.IndicationLabel,
  '00142018': exports.IndicationDescription,
  '0014201a': exports.IndicationType,
  '0014201c': exports.IndicationDisposition,
  '0014201e': exports.IndicationROISequence,
  '00142030': exports.IndicationPhysicalPropertySequence,
  '00142032': exports.PropertyLabel,
  '00142202': exports.CoordinateSystemNumberOfAxes,
  '00142204': exports.CoordinateSystemAxesSequence,
  '00142206': exports.CoordinateSystemAxisDescription,
  '00142208': exports.CoordinateSystemDataSetMapping,
  '0014220a': exports.CoordinateSystemAxisNumber,
  '0014220c': exports.CoordinateSystemAxisType,
  '0014220e': exports.CoordinateSystemAxisUnits,
  '00142210': exports.CoordinateSystemAxisValues,
  '00142220': exports.CoordinateSystemTransformSequence,
  '00142222': exports.TransformDescription,
  '00142224': exports.TransformNumberOfAxes,
  '00142226': exports.TransformOrderOfAxes,
  '00142228': exports.TransformedAxisUnits,
  '0014222a': exports.CoordinateSystemTransformRotationAndScaleMatrix,
  '0014222c': exports.CoordinateSystemTransformTranslationMatrix,
  '00143011': exports.InternalDetectorFrameTime,
  '00143012': exports.NumberOfFramesIntegrated,
  '00143020': exports.DetectorTemperatureSequence,
  '00143022': exports.SensorName,
  '00143024': exports.HorizontalOffsetOfSensor,
  '00143026': exports.VerticalOffsetOfSensor,
  '00143028': exports.SensorTemperature,
  '00143040': exports.DarkCurrentSequence,
  '00143050': exports.DarkCurrentCounts,
  '00143060': exports.GainCorrectionReferenceSequence,
  '00143070': exports.AirCounts,
  '00143071': exports.KVUsedInGainCalibration,
  '00143072': exports.MAUsedInGainCalibration,
  '00143073': exports.NumberOfFramesUsedForIntegration,
  '00143074': exports.FilterMaterialUsedInGainCalibration,
  '00143075': exports.FilterThicknessUsedInGainCalibration,
  '00143076': exports.DateOfGainCalibration,
  '00143077': exports.TimeOfGainCalibration,
  '00143080': exports.BadPixelImage,
  '00143099': exports.CalibrationNotes,
  '00144002': exports.PulserEquipmentSequence,
  '00144004': exports.PulserType,
  '00144006': exports.PulserNotes,
  '00144008': exports.ReceiverEquipmentSequence,
  '0014400a': exports.AmplifierType,
  '0014400c': exports.ReceiverNotes,
  '0014400e': exports.PreAmplifierEquipmentSequence,
  '0014400f': exports.PreAmplifierNotes,
  '00144010': exports.TransmitTransducerSequence,
  '00144011': exports.ReceiveTransducerSequence,
  '00144012': exports.NumberOfElements,
  '00144013': exports.ElementShape,
  '00144014': exports.ElementDimensionA,
  '00144015': exports.ElementDimensionB,
  '00144016': exports.ElementPitchA,
  '00144017': exports.MeasuredBeamDimensionA,
  '00144018': exports.MeasuredBeamDimensionB,
  '00144019': exports.LocationOfMeasuredBeamDiameter,
  '0014401a': exports.NominalFrequency,
  '0014401b': exports.MeasuredCenterFrequency,
  '0014401c': exports.MeasuredBandwidth,
  '0014401d': exports.ElementPitchB,
  '00144020': exports.PulserSettingsSequence,
  '00144022': exports.PulseWidth,
  '00144024': exports.ExcitationFrequency,
  '00144026': exports.ModulationType,
  '00144028': exports.Damping,
  '00144030': exports.ReceiverSettingsSequence,
  '00144031': exports.AcquiredSoundpathLength,
  '00144032': exports.AcquisitionCompressionType,
  '00144033': exports.AcquisitionSampleSize,
  '00144034': exports.RectifierSmoothing,
  '00144035': exports.DACSequence,
  '00144036': exports.DACType,
  '00144038': exports.DACGainPoints,
  '0014403a': exports.DACTimePoints,
  '0014403c': exports.DACAmplitude,
  '00144040': exports.PreAmplifierSettingsSequence,
  '00144050': exports.TransmitTransducerSettingsSequence,
  '00144051': exports.ReceiveTransducerSettingsSequence,
  '00144052': exports.IncidentAngle,
  '00144054': exports.CouplingTechnique,
  '00144056': exports.CouplingMedium,
  '00144057': exports.CouplingVelocity,
  '00144058': exports.ProbeCenterLocationX,
  '00144059': exports.ProbeCenterLocationZ,
  '0014405a': exports.SoundPathLength,
  '0014405c': exports.DelayLawIdentifier,
  '00144060': exports.GateSettingsSequence,
  '00144062': exports.GateThreshold,
  '00144064': exports.VelocityOfSound,
  '00144070': exports.CalibrationSettingsSequence,
  '00144072': exports.CalibrationProcedure,
  '00144074': exports.ProcedureVersion,
  '00144076': exports.ProcedureCreationDate,
  '00144078': exports.ProcedureExpirationDate,
  '0014407a': exports.ProcedureLastModifiedDate,
  '0014407c': exports.CalibrationTime,
  '0014407e': exports.CalibrationDate,
  '00144080': exports.ProbeDriveEquipmentSequence,
  '00144081': exports.DriveType,
  '00144082': exports.ProbeDriveNotes,
  '00144083': exports.DriveProbeSequence,
  '00144084': exports.ProbeInductance,
  '00144085': exports.ProbeResistance,
  '00144086': exports.ReceiveProbeSequence,
  '00144087': exports.ProbeDriveSettingsSequence,
  '00144088': exports.BridgeResistors,
  '00144089': exports.ProbeOrientationAngle,
  '0014408b': exports.UserSelectedGainY,
  '0014408c': exports.UserSelectedPhase,
  '0014408d': exports.UserSelectedOffsetX,
  '0014408e': exports.UserSelectedOffsetY,
  '00144091': exports.ChannelSettingsSequence,
  '00144092': exports.ChannelThreshold,
  '0014409a': exports.ScannerSettingsSequence,
  '0014409b': exports.ScanProcedure,
  '0014409c': exports.TranslationRateX,
  '0014409d': exports.TranslationRateY,
  '0014409f': exports.ChannelOverlap,
  '001440a0': exports.ImageQualityIndicatorType,
  '001440a1': exports.ImageQualityIndicatorMaterial,
  '001440a2': exports.ImageQualityIndicatorSize,
  '00145002': exports.LINACEnergy,
  '00145004': exports.LINACOutput,
  '00180010': exports.ContrastBolusAgent,
  '00180012': exports.ContrastBolusAgentSequence,
  '00180013': exports.ContrastBolusT1Relaxivity,
  '00180014': exports.ContrastBolusAdministrationRouteSequence,
  '00180015': exports.BodyPartExamined,
  '00180020': exports.ScanningSequence,
  '00180021': exports.SequenceVariant,
  '00180022': exports.ScanOptions,
  '00180023': exports.MRAcquisitionType,
  '00180024': exports.SequenceName,
  '00180025': exports.AngioFlag,
  '00180026': exports.InterventionDrugInformationSequence,
  '00180027': exports.InterventionDrugStopTime,
  '00180028': exports.InterventionDrugDose,
  '00180029': exports.InterventionDrugCodeSequence,
  '0018002a': exports.AdditionalDrugSequence,
  '00180030': exports.Radionuclide,
  '00180031': exports.Radiopharmaceutical,
  '00180032': exports.EnergyWindowCenterline,
  '00180033': exports.EnergyWindowTotalWidth,
  '00180034': exports.InterventionDrugName,
  '00180035': exports.InterventionDrugStartTime,
  '00180036': exports.InterventionSequence,
  '00180037': exports.TherapyType,
  '00180038': exports.InterventionStatus,
  '00180039': exports.TherapyDescription,
  '0018003a': exports.InterventionDescription,
  '00180040': exports.CineRate,
  '00180042': exports.InitialCineRunState,
  '00180050': exports.SliceThickness,
  '00180060': exports.KVP,
  '00180070': exports.CountsAccumulated,
  '00180071': exports.AcquisitionTerminationCondition,
  '00180072': exports.EffectiveDuration,
  '00180073': exports.AcquisitionStartCondition,
  '00180074': exports.AcquisitionStartConditionData,
  '00180075': exports.AcquisitionTerminationConditionData,
  '00180080': exports.RepetitionTime,
  '00180081': exports.EchoTime,
  '00180082': exports.InversionTime,
  '00180083': exports.NumberOfAverages,
  '00180084': exports.ImagingFrequency,
  '00180085': exports.ImagedNucleus,
  '00180086': exports.EchoNumbers,
  '00180087': exports.MagneticFieldStrength,
  '00180088': exports.SpacingBetweenSlices,
  '00180089': exports.NumberOfPhaseEncodingSteps,
  '00180090': exports.DataCollectionDiameter,
  '00180091': exports.EchoTrainLength,
  '00180093': exports.PercentSampling,
  '00180094': exports.PercentPhaseFieldOfView,
  '00180095': exports.PixelBandwidth,
  '00181000': exports.DeviceSerialNumber,
  '00181002': exports.DeviceUID,
  '00181003': exports.DeviceID,
  '00181004': exports.PlateID,
  '00181005': exports.GeneratorID,
  '00181006': exports.GridID,
  '00181007': exports.CassetteID,
  '00181008': exports.GantryID,
  '00181010': exports.SecondaryCaptureDeviceID,
  '00181011': exports.HardcopyCreationDeviceID,
  '00181012': exports.DateOfSecondaryCapture,
  '00181014': exports.TimeOfSecondaryCapture,
  '00181016': exports.SecondaryCaptureDeviceManufacturer,
  '00181017': exports.HardcopyDeviceManufacturer,
  '00181018': exports.SecondaryCaptureDeviceManufacturerModelName,
  '00181019': exports.SecondaryCaptureDeviceSoftwareVersions,
  '0018101a': exports.HardcopyDeviceSoftwareVersion,
  '0018101b': exports.HardcopyDeviceManufacturerModelName,
  '00181020': exports.SoftwareVersions,
  '00181022': exports.VideoImageFormatAcquired,
  '00181023': exports.DigitalImageFormatAcquired,
  '00181030': exports.ProtocolName,
  '00181040': exports.ContrastBolusRoute,
  '00181041': exports.ContrastBolusVolume,
  '00181042': exports.ContrastBolusStartTime,
  '00181043': exports.ContrastBolusStopTime,
  '00181044': exports.ContrastBolusTotalDose,
  '00181045': exports.SyringeCounts,
  '00181046': exports.ContrastFlowRate,
  '00181047': exports.ContrastFlowDuration,
  '00181048': exports.ContrastBolusIngredient,
  '00181049': exports.ContrastBolusIngredientConcentration,
  '00181050': exports.SpatialResolution,
  '00181060': exports.TriggerTime,
  '00181061': exports.TriggerSourceOrType,
  '00181062': exports.NominalInterval,
  '00181063': exports.FrameTime,
  '00181064': exports.CardiacFramingType,
  '00181065': exports.FrameTimeVector,
  '00181066': exports.FrameDelay,
  '00181067': exports.ImageTriggerDelay,
  '00181068': exports.MultiplexGroupTimeOffset,
  '00181069': exports.TriggerTimeOffset,
  '0018106a': exports.SynchronizationTrigger,
  '0018106c': exports.SynchronizationChannel,
  '0018106e': exports.TriggerSamplePosition,
  '00181070': exports.RadiopharmaceuticalRoute,
  '00181071': exports.RadiopharmaceuticalVolume,
  '00181072': exports.RadiopharmaceuticalStartTime,
  '00181073': exports.RadiopharmaceuticalStopTime,
  '00181074': exports.RadionuclideTotalDose,
  '00181075': exports.RadionuclideHalfLife,
  '00181076': exports.RadionuclidePositronFraction,
  '00181077': exports.RadiopharmaceuticalSpecificActivity,
  '00181078': exports.RadiopharmaceuticalStartDateTime,
  '00181079': exports.RadiopharmaceuticalStopDateTime,
  '00181080': exports.BeatRejectionFlag,
  '00181081': exports.LowRRValue,
  '00181082': exports.HighRRValue,
  '00181083': exports.IntervalsAcquired,
  '00181084': exports.IntervalsRejected,
  '00181085': exports.PVCRejection,
  '00181086': exports.SkipBeats,
  '00181088': exports.HeartRate,
  '00181090': exports.CardiacNumberOfImages,
  '00181094': exports.TriggerWindow,
  '00181100': exports.ReconstructionDiameter,
  '00181110': exports.DistanceSourceToDetector,
  '00181111': exports.DistanceSourceToPatient,
  '00181114': exports.EstimatedRadiographicMagnificationFactor,
  '00181120': exports.GantryDetectorTilt,
  '00181121': exports.GantryDetectorSlew,
  '00181130': exports.TableHeight,
  '00181131': exports.TableTraverse,
  '00181134': exports.TableMotion,
  '00181135': exports.TableVerticalIncrement,
  '00181136': exports.TableLateralIncrement,
  '00181137': exports.TableLongitudinalIncrement,
  '00181138': exports.TableAngle,
  '0018113a': exports.TableType,
  '00181140': exports.RotationDirection,
  '00181141': exports.AngularPosition,
  '00181142': exports.RadialPosition,
  '00181143': exports.ScanArc,
  '00181144': exports.AngularStep,
  '00181145': exports.CenterOfRotationOffset,
  '00181146': exports.RotationOffset,
  '00181147': exports.FieldOfViewShape,
  '00181149': exports.FieldOfViewDimensions,
  '00181150': exports.ExposureTime,
  '00181151': exports.XRayTubeCurrent,
  '00181152': exports.Exposure,
  '00181153': exports.ExposureInuAs,
  '00181154': exports.AveragePulseWidth,
  '00181155': exports.RadiationSetting,
  '00181156': exports.RectificationType,
  '0018115a': exports.RadiationMode,
  '0018115e': exports.ImageAndFluoroscopyAreaDoseProduct,
  '00181160': exports.FilterType,
  '00181161': exports.TypeOfFilters,
  '00181162': exports.IntensifierSize,
  '00181164': exports.ImagerPixelSpacing,
  '00181166': exports.Grid,
  '00181170': exports.GeneratorPower,
  '00181180': exports.CollimatorGridName,
  '00181181': exports.CollimatorType,
  '00181182': exports.FocalDistance,
  '00181183': exports.XFocusCenter,
  '00181184': exports.YFocusCenter,
  '00181190': exports.FocalSpots,
  '00181191': exports.AnodeTargetMaterial,
  '001811a0': exports.BodyPartThickness,
  '001811a2': exports.CompressionForce,
  '001811a4': exports.PaddleDescription,
  '00181200': exports.DateOfLastCalibration,
  '00181201': exports.TimeOfLastCalibration,
  '00181202': exports.DateTimeOfLastCalibration,
  '00181210': exports.ConvolutionKernel,
  '00181240': exports.UpperLowerPixelValues,
  '00181242': exports.ActualFrameDuration,
  '00181243': exports.CountRate,
  '00181244': exports.PreferredPlaybackSequencing,
  '00181250': exports.ReceiveCoilName,
  '00181251': exports.TransmitCoilName,
  '00181260': exports.PlateType,
  '00181261': exports.PhosphorType,
  '00181300': exports.ScanVelocity,
  '00181301': exports.WholeBodyTechnique,
  '00181302': exports.ScanLength,
  '00181310': exports.AcquisitionMatrix,
  '00181312': exports.InPlanePhaseEncodingDirection,
  '00181314': exports.FlipAngle,
  '00181315': exports.VariableFlipAngleFlag,
  '00181316': exports.SAR,
  '00181318': exports.dBdt,
  '00181400': exports.AcquisitionDeviceProcessingDescription,
  '00181401': exports.AcquisitionDeviceProcessingCode,
  '00181402': exports.CassetteOrientation,
  '00181403': exports.CassetteSize,
  '00181404': exports.ExposuresOnPlate,
  '00181405': exports.RelativeXRayExposure,
  '00181411': exports.ExposureIndex,
  '00181412': exports.TargetExposureIndex,
  '00181413': exports.DeviationIndex,
  '00181450': exports.ColumnAngulation,
  '00181460': exports.TomoLayerHeight,
  '00181470': exports.TomoAngle,
  '00181480': exports.TomoTime,
  '00181490': exports.TomoType,
  '00181491': exports.TomoClass,
  '00181495': exports.NumberOfTomosynthesisSourceImages,
  '00181500': exports.PositionerMotion,
  '00181508': exports.PositionerType,
  '00181510': exports.PositionerPrimaryAngle,
  '00181511': exports.PositionerSecondaryAngle,
  '00181520': exports.PositionerPrimaryAngleIncrement,
  '00181521': exports.PositionerSecondaryAngleIncrement,
  '00181530': exports.DetectorPrimaryAngle,
  '00181531': exports.DetectorSecondaryAngle,
  '00181600': exports.ShutterShape,
  '00181602': exports.ShutterLeftVerticalEdge,
  '00181604': exports.ShutterRightVerticalEdge,
  '00181606': exports.ShutterUpperHorizontalEdge,
  '00181608': exports.ShutterLowerHorizontalEdge,
  '00181610': exports.CenterOfCircularShutter,
  '00181612': exports.RadiusOfCircularShutter,
  '00181620': exports.VerticesOfThePolygonalShutter,
  '00181622': exports.ShutterPresentationValue,
  '00181623': exports.ShutterOverlayGroup,
  '00181624': exports.ShutterPresentationColorCIELabValue,
  '00181700': exports.CollimatorShape,
  '00181702': exports.CollimatorLeftVerticalEdge,
  '00181704': exports.CollimatorRightVerticalEdge,
  '00181706': exports.CollimatorUpperHorizontalEdge,
  '00181708': exports.CollimatorLowerHorizontalEdge,
  '00181710': exports.CenterOfCircularCollimator,
  '00181712': exports.RadiusOfCircularCollimator,
  '00181720': exports.VerticesOfThePolygonalCollimator,
  '00181800': exports.AcquisitionTimeSynchronized,
  '00181801': exports.TimeSource,
  '00181802': exports.TimeDistributionProtocol,
  '00181803': exports.NTPSourceAddress,
  '00182001': exports.PageNumberVector,
  '00182002': exports.FrameLabelVector,
  '00182003': exports.FramePrimaryAngleVector,
  '00182004': exports.FrameSecondaryAngleVector,
  '00182005': exports.SliceLocationVector,
  '00182006': exports.DisplayWindowLabelVector,
  '00182010': exports.NominalScannedPixelSpacing,
  '00182020': exports.DigitizingDeviceTransportDirection,
  '00182030': exports.RotationOfScannedFilm,
  '00182041': exports.BiopsyTargetSequence,
  '00182042': exports.TargetUID,
  '00182043': exports.LocalizingCursorPosition,
  '00182044': exports.CalculatedTargetPosition,
  '00182045': exports.TargetLabel,
  '00182046': exports.DisplayedZValue,
  '00183100': exports.IVUSAcquisition,
  '00183101': exports.IVUSPullbackRate,
  '00183102': exports.IVUSGatedRate,
  '00183103': exports.IVUSPullbackStartFrameNumber,
  '00183104': exports.IVUSPullbackStopFrameNumber,
  '00183105': exports.LesionNumber,
  '00184000': exports.AcquisitionComments,
  '00185000': exports.OutputPower,
  '00185010': exports.TransducerData,
  '00185012': exports.FocusDepth,
  '00185020': exports.ProcessingFunction,
  '00185021': exports.PostprocessingFunction,
  '00185022': exports.MechanicalIndex,
  '00185024': exports.BoneThermalIndex,
  '00185026': exports.CranialThermalIndex,
  '00185027': exports.SoftTissueThermalIndex,
  '00185028': exports.SoftTissueFocusThermalIndex,
  '00185029': exports.SoftTissueSurfaceThermalIndex,
  '00185030': exports.DynamicRange,
  '00185040': exports.TotalGain,
  '00185050': exports.DepthOfScanField,
  '00185100': exports.PatientPosition,
  '00185101': exports.ViewPosition,
  '00185104': exports.ProjectionEponymousNameCodeSequence,
  '00185210': exports.ImageTransformationMatrix,
  '00185212': exports.ImageTranslationVector,
  '00186000': exports.Sensitivity,
  '00186011': exports.SequenceOfUltrasoundRegions,
  '00186012': exports.RegionSpatialFormat,
  '00186014': exports.RegionDataType,
  '00186016': exports.RegionFlags,
  '00186018': exports.RegionLocationMinX0,
  '0018601a': exports.RegionLocationMinY0,
  '0018601c': exports.RegionLocationMaxX1,
  '0018601e': exports.RegionLocationMaxY1,
  '00186020': exports.ReferencePixelX0,
  '00186022': exports.ReferencePixelY0,
  '00186024': exports.PhysicalUnitsXDirection,
  '00186026': exports.PhysicalUnitsYDirection,
  '00186028': exports.ReferencePixelPhysicalValueX,
  '0018602a': exports.ReferencePixelPhysicalValueY,
  '0018602c': exports.PhysicalDeltaX,
  '0018602e': exports.PhysicalDeltaY,
  '00186030': exports.TransducerFrequency,
  '00186031': exports.TransducerType,
  '00186032': exports.PulseRepetitionFrequency,
  '00186034': exports.DopplerCorrectionAngle,
  '00186036': exports.SteeringAngle,
  '00186038': exports.DopplerSampleVolumeXPositionRetired,
  '00186039': exports.DopplerSampleVolumeXPosition,
  '0018603a': exports.DopplerSampleVolumeYPositionRetired,
  '0018603b': exports.DopplerSampleVolumeYPosition,
  '0018603c': exports.TMLinePositionX0Retired,
  '0018603d': exports.TMLinePositionX0,
  '0018603e': exports.TMLinePositionY0Retired,
  '0018603f': exports.TMLinePositionY0,
  '00186040': exports.TMLinePositionX1Retired,
  '00186041': exports.TMLinePositionX1,
  '00186042': exports.TMLinePositionY1Retired,
  '00186043': exports.TMLinePositionY1,
  '00186044': exports.PixelComponentOrganization,
  '00186046': exports.PixelComponentMask,
  '00186048': exports.PixelComponentRangeStart,
  '0018604a': exports.PixelComponentRangeStop,
  '0018604c': exports.PixelComponentPhysicalUnits,
  '0018604e': exports.PixelComponentDataType,
  '00186050': exports.NumberOfTableBreakPoints,
  '00186052': exports.TableOfXBreakPoints,
  '00186054': exports.TableOfYBreakPoints,
  '00186056': exports.NumberOfTableEntries,
  '00186058': exports.TableOfPixelValues,
  '0018605a': exports.TableOfParameterValues,
  '00186060': exports.RWaveTimeVector,
  '00187000': exports.DetectorConditionsNominalFlag,
  '00187001': exports.DetectorTemperature,
  '00187004': exports.DetectorType,
  '00187005': exports.DetectorConfiguration,
  '00187006': exports.DetectorDescription,
  '00187008': exports.DetectorMode,
  '0018700a': exports.DetectorID,
  '0018700c': exports.DateOfLastDetectorCalibration,
  '0018700e': exports.TimeOfLastDetectorCalibration,
  '00187010': exports.ExposuresOnDetectorSinceLastCalibration,
  '00187011': exports.ExposuresOnDetectorSinceManufactured,
  '00187012': exports.DetectorTimeSinceLastExposure,
  '00187014': exports.DetectorActiveTime,
  '00187016': exports.DetectorActivationOffsetFromExposure,
  '0018701a': exports.DetectorBinning,
  '00187020': exports.DetectorElementPhysicalSize,
  '00187022': exports.DetectorElementSpacing,
  '00187024': exports.DetectorActiveShape,
  '00187026': exports.DetectorActiveDimensions,
  '00187028': exports.DetectorActiveOrigin,
  '0018702a': exports.DetectorManufacturerName,
  '0018702b': exports.DetectorManufacturerModelName,
  '00187030': exports.FieldOfViewOrigin,
  '00187032': exports.FieldOfViewRotation,
  '00187034': exports.FieldOfViewHorizontalFlip,
  '00187036': exports.PixelDataAreaOriginRelativeToFOV,
  '00187038': exports.PixelDataAreaRotationAngleRelativeToFOV,
  '00187040': exports.GridAbsorbingMaterial,
  '00187041': exports.GridSpacingMaterial,
  '00187042': exports.GridThickness,
  '00187044': exports.GridPitch,
  '00187046': exports.GridAspectRatio,
  '00187048': exports.GridPeriod,
  '0018704c': exports.GridFocalDistance,
  '00187050': exports.FilterMaterial,
  '00187052': exports.FilterThicknessMinimum,
  '00187054': exports.FilterThicknessMaximum,
  '00187056': exports.FilterBeamPathLengthMinimum,
  '00187058': exports.FilterBeamPathLengthMaximum,
  '00187060': exports.ExposureControlMode,
  '00187062': exports.ExposureControlModeDescription,
  '00187064': exports.ExposureStatus,
  '00187065': exports.PhototimerSetting,
  '00188150': exports.ExposureTimeInuS,
  '00188151': exports.XRayTubeCurrentInuA,
  '00189004': exports.ContentQualification,
  '00189005': exports.PulseSequenceName,
  '00189006': exports.MRImagingModifierSequence,
  '00189008': exports.EchoPulseSequence,
  '00189009': exports.InversionRecovery,
  '00189010': exports.FlowCompensation,
  '00189011': exports.MultipleSpinEcho,
  '00189012': exports.MultiPlanarExcitation,
  '00189014': exports.PhaseContrast,
  '00189015': exports.TimeOfFlightContrast,
  '00189016': exports.Spoiling,
  '00189017': exports.SteadyStatePulseSequence,
  '00189018': exports.EchoPlanarPulseSequence,
  '00189019': exports.TagAngleFirstAxis,
  '00189020': exports.MagnetizationTransfer,
  '00189021': exports.T2Preparation,
  '00189022': exports.BloodSignalNulling,
  '00189024': exports.SaturationRecovery,
  '00189025': exports.SpectrallySelectedSuppression,
  '00189026': exports.SpectrallySelectedExcitation,
  '00189027': exports.SpatialPresaturation,
  '00189028': exports.Tagging,
  '00189029': exports.OversamplingPhase,
  '00189030': exports.TagSpacingFirstDimension,
  '00189032': exports.GeometryOfKSpaceTraversal,
  '00189033': exports.SegmentedKSpaceTraversal,
  '00189034': exports.RectilinearPhaseEncodeReordering,
  '00189035': exports.TagThickness,
  '00189036': exports.PartialFourierDirection,
  '00189037': exports.CardiacSynchronizationTechnique,
  '00189041': exports.ReceiveCoilManufacturerName,
  '00189042': exports.MRReceiveCoilSequence,
  '00189043': exports.ReceiveCoilType,
  '00189044': exports.QuadratureReceiveCoil,
  '00189045': exports.MultiCoilDefinitionSequence,
  '00189046': exports.MultiCoilConfiguration,
  '00189047': exports.MultiCoilElementName,
  '00189048': exports.MultiCoilElementUsed,
  '00189049': exports.MRTransmitCoilSequence,
  '00189050': exports.TransmitCoilManufacturerName,
  '00189051': exports.TransmitCoilType,
  '00189052': exports.SpectralWidth,
  '00189053': exports.ChemicalShiftReference,
  '00189054': exports.VolumeLocalizationTechnique,
  '00189058': exports.MRAcquisitionFrequencyEncodingSteps,
  '00189059': exports.Decoupling,
  '00189060': exports.DecoupledNucleus,
  '00189061': exports.DecouplingFrequency,
  '00189062': exports.DecouplingMethod,
  '00189063': exports.DecouplingChemicalShiftReference,
  '00189064': exports.KSpaceFiltering,
  '00189065': exports.TimeDomainFiltering,
  '00189066': exports.NumberOfZeroFills,
  '00189067': exports.BaselineCorrection,
  '00189069': exports.ParallelReductionFactorInPlane,
  '00189070': exports.CardiacRRIntervalSpecified,
  '00189073': exports.AcquisitionDuration,
  '00189074': exports.FrameAcquisitionDateTime,
  '00189075': exports.DiffusionDirectionality,
  '00189076': exports.DiffusionGradientDirectionSequence,
  '00189077': exports.ParallelAcquisition,
  '00189078': exports.ParallelAcquisitionTechnique,
  '00189079': exports.InversionTimes,
  '00189080': exports.MetaboliteMapDescription,
  '00189081': exports.PartialFourier,
  '00189082': exports.EffectiveEchoTime,
  '00189083': exports.MetaboliteMapCodeSequence,
  '00189084': exports.ChemicalShiftSequence,
  '00189085': exports.CardiacSignalSource,
  '00189087': exports.DiffusionBValue,
  '00189089': exports.DiffusionGradientOrientation,
  '00189090': exports.VelocityEncodingDirection,
  '00189091': exports.VelocityEncodingMinimumValue,
  '00189092': exports.VelocityEncodingAcquisitionSequence,
  '00189093': exports.NumberOfKSpaceTrajectories,
  '00189094': exports.CoverageOfKSpace,
  '00189095': exports.SpectroscopyAcquisitionPhaseRows,
  '00189096': exports.ParallelReductionFactorInPlaneRetired,
  '00189098': exports.TransmitterFrequency,
  '00189100': exports.ResonantNucleus,
  '00189101': exports.FrequencyCorrection,
  '00189103': exports.MRSpectroscopyFOVGeometrySequence,
  '00189104': exports.SlabThickness,
  '00189105': exports.SlabOrientation,
  '00189106': exports.MidSlabPosition,
  '00189107': exports.MRSpatialSaturationSequence,
  '00189112': exports.MRTimingAndRelatedParametersSequence,
  '00189114': exports.MREchoSequence,
  '00189115': exports.MRModifierSequence,
  '00189117': exports.MRDiffusionSequence,
  '00189118': exports.CardiacSynchronizationSequence,
  '00189119': exports.MRAveragesSequence,
  '00189125': exports.MRFOVGeometrySequence,
  '00189126': exports.VolumeLocalizationSequence,
  '00189127': exports.SpectroscopyAcquisitionDataColumns,
  '00189147': exports.DiffusionAnisotropyType,
  '00189151': exports.FrameReferenceDateTime,
  '00189152': exports.MRMetaboliteMapSequence,
  '00189155': exports.ParallelReductionFactorOutOfPlane,
  '00189159': exports.SpectroscopyAcquisitionOutOfPlanePhaseSteps,
  '00189166': exports.BulkMotionStatus,
  '00189168': exports.ParallelReductionFactorSecondInPlane,
  '00189169': exports.CardiacBeatRejectionTechnique,
  '00189170': exports.RespiratoryMotionCompensationTechnique,
  '00189171': exports.RespiratorySignalSource,
  '00189172': exports.BulkMotionCompensationTechnique,
  '00189173': exports.BulkMotionSignalSource,
  '00189174': exports.ApplicableSafetyStandardAgency,
  '00189175': exports.ApplicableSafetyStandardDescription,
  '00189176': exports.OperatingModeSequence,
  '00189177': exports.OperatingModeType,
  '00189178': exports.OperatingMode,
  '00189179': exports.SpecificAbsorptionRateDefinition,
  '00189180': exports.GradientOutputType,
  '00189181': exports.SpecificAbsorptionRateValue,
  '00189182': exports.GradientOutput,
  '00189183': exports.FlowCompensationDirection,
  '00189184': exports.TaggingDelay,
  '00189185': exports.RespiratoryMotionCompensationTechniqueDescription,
  '00189186': exports.RespiratorySignalSourceID,
  '00189195': exports.ChemicalShiftMinimumIntegrationLimitInHz,
  '00189196': exports.ChemicalShiftMaximumIntegrationLimitInHz,
  '00189197': exports.MRVelocityEncodingSequence,
  '00189198': exports.FirstOrderPhaseCorrection,
  '00189199': exports.WaterReferencedPhaseCorrection,
  '00189200': exports.MRSpectroscopyAcquisitionType,
  '00189214': exports.RespiratoryCyclePosition,
  '00189217': exports.VelocityEncodingMaximumValue,
  '00189218': exports.TagSpacingSecondDimension,
  '00189219': exports.TagAngleSecondAxis,
  '00189220': exports.FrameAcquisitionDuration,
  '00189226': exports.MRImageFrameTypeSequence,
  '00189227': exports.MRSpectroscopyFrameTypeSequence,
  '00189231': exports.MRAcquisitionPhaseEncodingStepsInPlane,
  '00189232': exports.MRAcquisitionPhaseEncodingStepsOutOfPlane,
  '00189234': exports.SpectroscopyAcquisitionPhaseColumns,
  '00189236': exports.CardiacCyclePosition,
  '00189239': exports.SpecificAbsorptionRateSequence,
  '00189240': exports.RFEchoTrainLength,
  '00189241': exports.GradientEchoTrainLength,
  '00189250': exports.ArterialSpinLabelingContrast,
  '00189251': exports.MRArterialSpinLabelingSequence,
  '00189252': exports.ASLTechniqueDescription,
  '00189253': exports.ASLSlabNumber,
  '00189254': exports.ASLSlabThickness,
  '00189255': exports.ASLSlabOrientation,
  '00189256': exports.ASLMidSlabPosition,
  '00189257': exports.ASLContext,
  '00189258': exports.ASLPulseTrainDuration,
  '00189259': exports.ASLCrusherFlag,
  '0018925a': exports.ASLCrusherFlowLimit,
  '0018925b': exports.ASLCrusherDescription,
  '0018925c': exports.ASLBolusCutoffFlag,
  '0018925d': exports.ASLBolusCutoffTimingSequence,
  '0018925e': exports.ASLBolusCutoffTechnique,
  '0018925f': exports.ASLBolusCutoffDelayTime,
  '00189260': exports.ASLSlabSequence,
  '00189295': exports.ChemicalShiftMinimumIntegrationLimitInppm,
  '00189296': exports.ChemicalShiftMaximumIntegrationLimitInppm,
  '00189297': exports.WaterReferenceAcquisition,
  '00189298': exports.EchoPeakPosition,
  '00189301': exports.CTAcquisitionTypeSequence,
  '00189302': exports.AcquisitionType,
  '00189303': exports.TubeAngle,
  '00189304': exports.CTAcquisitionDetailsSequence,
  '00189305': exports.RevolutionTime,
  '00189306': exports.SingleCollimationWidth,
  '00189307': exports.TotalCollimationWidth,
  '00189308': exports.CTTableDynamicsSequence,
  '00189309': exports.TableSpeed,
  '00189310': exports.TableFeedPerRotation,
  '00189311': exports.SpiralPitchFactor,
  '00189312': exports.CTGeometrySequence,
  '00189313': exports.DataCollectionCenterPatient,
  '00189314': exports.CTReconstructionSequence,
  '00189315': exports.ReconstructionAlgorithm,
  '00189316': exports.ConvolutionKernelGroup,
  '00189317': exports.ReconstructionFieldOfView,
  '00189318': exports.ReconstructionTargetCenterPatient,
  '00189319': exports.ReconstructionAngle,
  '00189320': exports.ImageFilter,
  '00189321': exports.CTExposureSequence,
  '00189322': exports.ReconstructionPixelSpacing,
  '00189323': exports.ExposureModulationType,
  '00189324': exports.EstimatedDoseSaving,
  '00189325': exports.CTXRayDetailsSequence,
  '00189326': exports.CTPositionSequence,
  '00189327': exports.TablePosition,
  '00189328': exports.ExposureTimeInms,
  '00189329': exports.CTImageFrameTypeSequence,
  '00189330': exports.XRayTubeCurrentInmA,
  '00189332': exports.ExposureInmAs,
  '00189333': exports.ConstantVolumeFlag,
  '00189334': exports.FluoroscopyFlag,
  '00189335': exports.DistanceSourceToDataCollectionCenter,
  '00189337': exports.ContrastBolusAgentNumber,
  '00189338': exports.ContrastBolusIngredientCodeSequence,
  '00189340': exports.ContrastAdministrationProfileSequence,
  '00189341': exports.ContrastBolusUsageSequence,
  '00189342': exports.ContrastBolusAgentAdministered,
  '00189343': exports.ContrastBolusAgentDetected,
  '00189344': exports.ContrastBolusAgentPhase,
  '00189345': exports.CTDIvol,
  '00189346': exports.CTDIPhantomTypeCodeSequence,
  '00189351': exports.CalciumScoringMassFactorPatient,
  '00189352': exports.CalciumScoringMassFactorDevice,
  '00189353': exports.EnergyWeightingFactor,
  '00189360': exports.CTAdditionalXRaySourceSequence,
  '00189401': exports.ProjectionPixelCalibrationSequence,
  '00189402': exports.DistanceSourceToIsocenter,
  '00189403': exports.DistanceObjectToTableTop,
  '00189404': exports.ObjectPixelSpacingInCenterOfBeam,
  '00189405': exports.PositionerPositionSequence,
  '00189406': exports.TablePositionSequence,
  '00189407': exports.CollimatorShapeSequence,
  '00189410': exports.PlanesInAcquisition,
  '00189412': exports.XAXRFFrameCharacteristicsSequence,
  '00189417': exports.FrameAcquisitionSequence,
  '00189420': exports.XRayReceptorType,
  '00189423': exports.AcquisitionProtocolName,
  '00189424': exports.AcquisitionProtocolDescription,
  '00189425': exports.ContrastBolusIngredientOpaque,
  '00189426': exports.DistanceReceptorPlaneToDetectorHousing,
  '00189427': exports.IntensifierActiveShape,
  '00189428': exports.IntensifierActiveDimensions,
  '00189429': exports.PhysicalDetectorSize,
  '00189430': exports.PositionOfIsocenterProjection,
  '00189432': exports.FieldOfViewSequence,
  '00189433': exports.FieldOfViewDescription,
  '00189434': exports.ExposureControlSensingRegionsSequence,
  '00189435': exports.ExposureControlSensingRegionShape,
  '00189436': exports.ExposureControlSensingRegionLeftVerticalEdge,
  '00189437': exports.ExposureControlSensingRegionRightVerticalEdge,
  '00189438': exports.ExposureControlSensingRegionUpperHorizontalEdge,
  '00189439': exports.ExposureControlSensingRegionLowerHorizontalEdge,
  '00189440': exports.CenterOfCircularExposureControlSensingRegion,
  '00189441': exports.RadiusOfCircularExposureControlSensingRegion,
  '00189442': exports.VerticesOfThePolygonalExposureControlSensingRegion,
  '00189447': exports.ColumnAngulationPatient,
  '00189449': exports.BeamAngle,
  '00189451': exports.FrameDetectorParametersSequence,
  '00189452': exports.CalculatedAnatomyThickness,
  '00189455': exports.CalibrationSequence,
  '00189456': exports.ObjectThicknessSequence,
  '00189457': exports.PlaneIdentification,
  '00189461': exports.FieldOfViewDimensionsInFloat,
  '00189462': exports.IsocenterReferenceSystemSequence,
  '00189463': exports.PositionerIsocenterPrimaryAngle,
  '00189464': exports.PositionerIsocenterSecondaryAngle,
  '00189465': exports.PositionerIsocenterDetectorRotationAngle,
  '00189466': exports.TableXPositionToIsocenter,
  '00189467': exports.TableYPositionToIsocenter,
  '00189468': exports.TableZPositionToIsocenter,
  '00189469': exports.TableHorizontalRotationAngle,
  '00189470': exports.TableHeadTiltAngle,
  '00189471': exports.TableCradleTiltAngle,
  '00189472': exports.FrameDisplayShutterSequence,
  '00189473': exports.AcquiredImageAreaDoseProduct,
  '00189474': exports.CArmPositionerTabletopRelationship,
  '00189476': exports.XRayGeometrySequence,
  '00189477': exports.IrradiationEventIdentificationSequence,
  '00189504': exports.XRay3DFrameTypeSequence,
  '00189506': exports.ContributingSourcesSequence,
  '00189507': exports.XRay3DAcquisitionSequence,
  '00189508': exports.PrimaryPositionerScanArc,
  '00189509': exports.SecondaryPositionerScanArc,
  '00189510': exports.PrimaryPositionerScanStartAngle,
  '00189511': exports.SecondaryPositionerScanStartAngle,
  '00189514': exports.PrimaryPositionerIncrement,
  '00189515': exports.SecondaryPositionerIncrement,
  '00189516': exports.StartAcquisitionDateTime,
  '00189517': exports.EndAcquisitionDateTime,
  '00189518': exports.PrimaryPositionerIncrementSign,
  '00189519': exports.SecondaryPositionerIncrementSign,
  '00189524': exports.ApplicationName,
  '00189525': exports.ApplicationVersion,
  '00189526': exports.ApplicationManufacturer,
  '00189527': exports.AlgorithmType,
  '00189528': exports.AlgorithmDescription,
  '00189530': exports.XRay3DReconstructionSequence,
  '00189531': exports.ReconstructionDescription,
  '00189538': exports.PerProjectionAcquisitionSequence,
  '00189541': exports.DetectorPositionSequence,
  '00189542': exports.XRayAcquisitionDoseSequence,
  '00189543': exports.XRaySourceIsocenterPrimaryAngle,
  '00189544': exports.XRaySourceIsocenterSecondaryAngle,
  '00189545': exports.BreastSupportIsocenterPrimaryAngle,
  '00189546': exports.BreastSupportIsocenterSecondaryAngle,
  '00189547': exports.BreastSupportXPositionToIsocenter,
  '00189548': exports.BreastSupportYPositionToIsocenter,
  '00189549': exports.BreastSupportZPositionToIsocenter,
  '00189550': exports.DetectorIsocenterPrimaryAngle,
  '00189551': exports.DetectorIsocenterSecondaryAngle,
  '00189552': exports.DetectorXPositionToIsocenter,
  '00189553': exports.DetectorYPositionToIsocenter,
  '00189554': exports.DetectorZPositionToIsocenter,
  '00189555': exports.XRayGridSequence,
  '00189556': exports.XRayFilterSequence,
  '00189557': exports.DetectorActiveAreaTLHCPosition,
  '00189558': exports.DetectorActiveAreaOrientation,
  '00189559': exports.PositionerPrimaryAngleDirection,
  '00189601': exports.DiffusionBMatrixSequence,
  '00189602': exports.DiffusionBValueXX,
  '00189603': exports.DiffusionBValueXY,
  '00189604': exports.DiffusionBValueXZ,
  '00189605': exports.DiffusionBValueYY,
  '00189606': exports.DiffusionBValueYZ,
  '00189607': exports.DiffusionBValueZZ,
  '00189701': exports.DecayCorrectionDateTime,
  '00189715': exports.StartDensityThreshold,
  '00189716': exports.StartRelativeDensityDifferenceThreshold,
  '00189717': exports.StartCardiacTriggerCountThreshold,
  '00189718': exports.StartRespiratoryTriggerCountThreshold,
  '00189719': exports.TerminationCountsThreshold,
  '00189720': exports.TerminationDensityThreshold,
  '00189721': exports.TerminationRelativeDensityThreshold,
  '00189722': exports.TerminationTimeThreshold,
  '00189723': exports.TerminationCardiacTriggerCountThreshold,
  '00189724': exports.TerminationRespiratoryTriggerCountThreshold,
  '00189725': exports.DetectorGeometry,
  '00189726': exports.TransverseDetectorSeparation,
  '00189727': exports.AxialDetectorDimension,
  '00189729': exports.RadiopharmaceuticalAgentNumber,
  '00189732': exports.PETFrameAcquisitionSequence,
  '00189733': exports.PETDetectorMotionDetailsSequence,
  '00189734': exports.PETTableDynamicsSequence,
  '00189735': exports.PETPositionSequence,
  '00189736': exports.PETFrameCorrectionFactorsSequence,
  '00189737': exports.RadiopharmaceuticalUsageSequence,
  '00189738': exports.AttenuationCorrectionSource,
  '00189739': exports.NumberOfIterations,
  '00189740': exports.NumberOfSubsets,
  '00189749': exports.PETReconstructionSequence,
  '00189751': exports.PETFrameTypeSequence,
  '00189755': exports.TimeOfFlightInformationUsed,
  '00189756': exports.ReconstructionType,
  '00189758': exports.DecayCorrected,
  '00189759': exports.AttenuationCorrected,
  '00189760': exports.ScatterCorrected,
  '00189761': exports.DeadTimeCorrected,
  '00189762': exports.GantryMotionCorrected,
  '00189763': exports.PatientMotionCorrected,
  '00189764': exports.CountLossNormalizationCorrected,
  '00189765': exports.RandomsCorrected,
  '00189766': exports.NonUniformRadialSamplingCorrected,
  '00189767': exports.SensitivityCalibrated,
  '00189768': exports.DetectorNormalizationCorrection,
  '00189769': exports.IterativeReconstructionMethod,
  '00189770': exports.AttenuationCorrectionTemporalRelationship,
  '00189771': exports.PatientPhysiologicalStateSequence,
  '00189772': exports.PatientPhysiologicalStateCodeSequence,
  '00189801': exports.DepthsOfFocus,
  '00189803': exports.ExcludedIntervalsSequence,
  '00189804': exports.ExclusionStartDateTime,
  '00189805': exports.ExclusionDuration,
  '00189806': exports.USImageDescriptionSequence,
  '00189807': exports.ImageDataTypeSequence,
  '00189808': exports.DataType,
  '00189809': exports.TransducerScanPatternCodeSequence,
  '0018980b': exports.AliasedDataType,
  '0018980c': exports.PositionMeasuringDeviceUsed,
  '0018980d': exports.TransducerGeometryCodeSequence,
  '0018980e': exports.TransducerBeamSteeringCodeSequence,
  '0018980f': exports.TransducerApplicationCodeSequence,
  '00189810': exports.ZeroVelocityPixelValue,
  '0018a001': exports.ContributingEquipmentSequence,
  '0018a002': exports.ContributionDateTime,
  '0018a003': exports.ContributionDescription,
  '0020000d': exports.StudyInstanceUID,
  '0020000e': exports.SeriesInstanceUID,
  '00200010': exports.StudyID,
  '00200011': exports.SeriesNumber,
  '00200012': exports.AcquisitionNumber,
  '00200013': exports.InstanceNumber,
  '00200014': exports.IsotopeNumber,
  '00200015': exports.PhaseNumber,
  '00200016': exports.IntervalNumber,
  '00200017': exports.TimeSlotNumber,
  '00200018': exports.AngleNumber,
  '00200019': exports.ItemNumber,
  '00200020': exports.PatientOrientation,
  '00200022': exports.OverlayNumber,
  '00200024': exports.CurveNumber,
  '00200026': exports.LUTNumber,
  '00200030': exports.ImagePosition,
  '00200032': exports.ImagePositionPatient,
  '00200035': exports.ImageOrientation,
  '00200037': exports.ImageOrientationPatient,
  '00200050': exports.Location,
  '00200052': exports.FrameOfReferenceUID,
  '00200060': exports.Laterality,
  '00200062': exports.ImageLaterality,
  '00200070': exports.ImageGeometryType,
  '00200080': exports.MaskingImage,
  '002000aa': exports.ReportNumber,
  '00200100': exports.TemporalPositionIdentifier,
  '00200105': exports.NumberOfTemporalPositions,
  '00200110': exports.TemporalResolution,
  '00200200': exports.SynchronizationFrameOfReferenceUID,
  '00200242': exports.SOPInstanceUIDOfConcatenationSource,
  '00201000': exports.SeriesInStudy,
  '00201001': exports.AcquisitionsInSeries,
  '00201002': exports.ImagesInAcquisition,
  '00201003': exports.ImagesInSeries,
  '00201004': exports.AcquisitionsInStudy,
  '00201005': exports.ImagesInStudy,
  '00201020': exports.Reference,
  '00201040': exports.PositionReferenceIndicator,
  '00201041': exports.SliceLocation,
  '00201070': exports.OtherStudyNumbers,
  '00201200': exports.NumberOfPatientRelatedStudies,
  '00201202': exports.NumberOfPatientRelatedSeries,
  '00201204': exports.NumberOfPatientRelatedInstances,
  '00201206': exports.NumberOfStudyRelatedSeries,
  '00201208': exports.NumberOfStudyRelatedInstances,
  '00201209': exports.NumberOfSeriesRelatedInstances,
  '00203100': exports.SourceImageIDs,
  '00203401': exports.ModifyingDeviceID,
  '00203402': exports.ModifiedImageID,
  '00203403': exports.ModifiedImageDate,
  '00203404': exports.ModifyingDeviceManufacturer,
  '00203405': exports.ModifiedImageTime,
  '00203406': exports.ModifiedImageDescription,
  '00204000': exports.ImageComments,
  '00205000': exports.OriginalImageIdentification,
  '00205002': exports.OriginalImageIdentificationNomenclature,
  '00209056': exports.StackID,
  '00209057': exports.InStackPositionNumber,
  '00209071': exports.FrameAnatomySequence,
  '00209072': exports.FrameLaterality,
  '00209111': exports.FrameContentSequence,
  '00209113': exports.PlanePositionSequence,
  '00209116': exports.PlaneOrientationSequence,
  '00209128': exports.TemporalPositionIndex,
  '00209153': exports.NominalCardiacTriggerDelayTime,
  '00209154': exports.NominalCardiacTriggerTimePriorToRPeak,
  '00209155': exports.ActualCardiacTriggerTimePriorToRPeak,
  '00209156': exports.FrameAcquisitionNumber,
  '00209157': exports.DimensionIndexValues,
  '00209158': exports.FrameComments,
  '00209161': exports.ConcatenationUID,
  '00209162': exports.InConcatenationNumber,
  '00209163': exports.InConcatenationTotalNumber,
  '00209164': exports.DimensionOrganizationUID,
  '00209165': exports.DimensionIndexPointer,
  '00209167': exports.FunctionalGroupPointer,
  '00209170': exports.UnassignedSharedConvertedAttributesSequence,
  '00209171': exports.UnassignedPerFrameConvertedAttributesSequence,
  '00209172': exports.ConversionSourceAttributesSequence,
  '00209213': exports.DimensionIndexPrivateCreator,
  '00209221': exports.DimensionOrganizationSequence,
  '00209222': exports.DimensionIndexSequence,
  '00209228': exports.ConcatenationFrameOffsetNumber,
  '00209238': exports.FunctionalGroupPrivateCreator,
  '00209241': exports.NominalPercentageOfCardiacPhase,
  '00209245': exports.NominalPercentageOfRespiratoryPhase,
  '00209246': exports.StartingRespiratoryAmplitude,
  '00209247': exports.StartingRespiratoryPhase,
  '00209248': exports.EndingRespiratoryAmplitude,
  '00209249': exports.EndingRespiratoryPhase,
  '00209250': exports.RespiratoryTriggerType,
  '00209251': exports.RRIntervalTimeNominal,
  '00209252': exports.ActualCardiacTriggerDelayTime,
  '00209253': exports.RespiratorySynchronizationSequence,
  '00209254': exports.RespiratoryIntervalTime,
  '00209255': exports.NominalRespiratoryTriggerDelayTime,
  '00209256': exports.RespiratoryTriggerDelayThreshold,
  '00209257': exports.ActualRespiratoryTriggerDelayTime,
  '00209301': exports.ImagePositionVolume,
  '00209302': exports.ImageOrientationVolume,
  '00209307': exports.UltrasoundAcquisitionGeometry,
  '00209308': exports.ApexPosition,
  '00209309': exports.VolumeToTransducerMappingMatrix,
  '0020930a': exports.VolumeToTableMappingMatrix,
  '0020930b': exports.VolumeToTransducerRelationship,
  '0020930c': exports.PatientFrameOfReferenceSource,
  '0020930d': exports.TemporalPositionTimeOffset,
  '0020930e': exports.PlanePositionVolumeSequence,
  '0020930f': exports.PlaneOrientationVolumeSequence,
  '00209310': exports.TemporalPositionSequence,
  '00209311': exports.DimensionOrganizationType,
  '00209312': exports.VolumeFrameOfReferenceUID,
  '00209313': exports.TableFrameOfReferenceUID,
  '00209421': exports.DimensionDescriptionLabel,
  '00209450': exports.PatientOrientationInFrameSequence,
  '00209453': exports.FrameLabel,
  '00209518': exports.AcquisitionIndex,
  '00209529': exports.ContributingSOPInstancesReferenceSequence,
  '00209536': exports.ReconstructionIndex,
  '00220001': exports.LightPathFilterPassThroughWavelength,
  '00220002': exports.LightPathFilterPassBand,
  '00220003': exports.ImagePathFilterPassThroughWavelength,
  '00220004': exports.ImagePathFilterPassBand,
  '00220005': exports.PatientEyeMovementCommanded,
  '00220006': exports.PatientEyeMovementCommandCodeSequence,
  '00220007': exports.SphericalLensPower,
  '00220008': exports.CylinderLensPower,
  '00220009': exports.CylinderAxis,
  '0022000a': exports.EmmetropicMagnification,
  '0022000b': exports.IntraOcularPressure,
  '0022000c': exports.HorizontalFieldOfView,
  '0022000d': exports.PupilDilated,
  '0022000e': exports.DegreeOfDilation,
  '00220010': exports.StereoBaselineAngle,
  '00220011': exports.StereoBaselineDisplacement,
  '00220012': exports.StereoHorizontalPixelOffset,
  '00220013': exports.StereoVerticalPixelOffset,
  '00220014': exports.StereoRotation,
  '00220015': exports.AcquisitionDeviceTypeCodeSequence,
  '00220016': exports.IlluminationTypeCodeSequence,
  '00220017': exports.LightPathFilterTypeStackCodeSequence,
  '00220018': exports.ImagePathFilterTypeStackCodeSequence,
  '00220019': exports.LensesCodeSequence,
  '0022001a': exports.ChannelDescriptionCodeSequence,
  '0022001b': exports.RefractiveStateSequence,
  '0022001c': exports.MydriaticAgentCodeSequence,
  '0022001d': exports.RelativeImagePositionCodeSequence,
  '0022001e': exports.CameraAngleOfView,
  '00220020': exports.StereoPairsSequence,
  '00220021': exports.LeftImageSequence,
  '00220022': exports.RightImageSequence,
  '00220030': exports.AxialLengthOfTheEye,
  '00220031': exports.OphthalmicFrameLocationSequence,
  '00220032': exports.ReferenceCoordinates,
  '00220035': exports.DepthSpatialResolution,
  '00220036': exports.MaximumDepthDistortion,
  '00220037': exports.AlongScanSpatialResolution,
  '00220038': exports.MaximumAlongScanDistortion,
  '00220039': exports.OphthalmicImageOrientation,
  '00220041': exports.DepthOfTransverseImage,
  '00220042': exports.MydriaticAgentConcentrationUnitsSequence,
  '00220048': exports.AcrossScanSpatialResolution,
  '00220049': exports.MaximumAcrossScanDistortion,
  '0022004e': exports.MydriaticAgentConcentration,
  '00220055': exports.IlluminationWaveLength,
  '00220056': exports.IlluminationPower,
  '00220057': exports.IlluminationBandwidth,
  '00220058': exports.MydriaticAgentSequence,
  '00221007': exports.OphthalmicAxialMeasurementsRightEyeSequence,
  '00221008': exports.OphthalmicAxialMeasurementsLeftEyeSequence,
  '00221009': exports.OphthalmicAxialMeasurementsDeviceType,
  '00221010': exports.OphthalmicAxialLengthMeasurementsType,
  '00221012': exports.OphthalmicAxialLengthSequence,
  '00221019': exports.OphthalmicAxialLength,
  '00221024': exports.LensStatusCodeSequence,
  '00221025': exports.VitreousStatusCodeSequence,
  '00221028': exports.IOLFormulaCodeSequence,
  '00221029': exports.IOLFormulaDetail,
  '00221033': exports.KeratometerIndex,
  '00221035': exports.SourceOfOphthalmicAxialLengthCodeSequence,
  '00221037': exports.TargetRefraction,
  '00221039': exports.RefractiveProcedureOccurred,
  '00221040': exports.RefractiveSurgeryTypeCodeSequence,
  '00221044': exports.OphthalmicUltrasoundMethodCodeSequence,
  '00221050': exports.OphthalmicAxialLengthMeasurementsSequence,
  '00221053': exports.IOLPower,
  '00221054': exports.PredictedRefractiveError,
  '00221059': exports.OphthalmicAxialLengthVelocity,
  '00221065': exports.LensStatusDescription,
  '00221066': exports.VitreousStatusDescription,
  '00221090': exports.IOLPowerSequence,
  '00221092': exports.LensConstantSequence,
  '00221093': exports.IOLManufacturer,
  '00221094': exports.LensConstantDescription,
  '00221095': exports.ImplantName,
  '00221096': exports.KeratometryMeasurementTypeCodeSequence,
  '00221097': exports.ImplantPartNumber,
  '00221100': exports.ReferencedOphthalmicAxialMeasurementsSequence,
  '00221101': exports.OphthalmicAxialLengthMeasurementsSegmentNameCodeSequence,
  '00221103': exports.RefractiveErrorBeforeRefractiveSurgeryCodeSequence,
  '00221121': exports.IOLPowerForExactEmmetropia,
  '00221122': exports.IOLPowerForExactTargetRefraction,
  '00221125': exports.AnteriorChamberDepthDefinitionCodeSequence,
  '00221127': exports.LensThicknessSequence,
  '00221128': exports.AnteriorChamberDepthSequence,
  '00221130': exports.LensThickness,
  '00221131': exports.AnteriorChamberDepth,
  '00221132': exports.SourceOfLensThicknessDataCodeSequence,
  '00221133': exports.SourceOfAnteriorChamberDepthDataCodeSequence,
  '00221134': exports.SourceOfRefractiveMeasurementsSequence,
  '00221135': exports.SourceOfRefractiveMeasurementsCodeSequence,
  '00221140': exports.OphthalmicAxialLengthMeasurementModified,
  '00221150': exports.OphthalmicAxialLengthDataSourceCodeSequence,
  '00221153': exports.OphthalmicAxialLengthAcquisitionMethodCodeSequence,
  '00221155': exports.SignalToNoiseRatio,
  '00221159': exports.OphthalmicAxialLengthDataSourceDescription,
  '00221210': exports.OphthalmicAxialLengthMeasurementsTotalLengthSequence,
  '00221211': exports.OphthalmicAxialLengthMeasurementsSegmentalLengthSequence,
  '00221212': exports.OphthalmicAxialLengthMeasurementsLengthSummationSequence,
  '00221220': exports.UltrasoundOphthalmicAxialLengthMeasurementsSequence,
  '00221225': exports.OpticalOphthalmicAxialLengthMeasurementsSequence,
  '00221230': exports.UltrasoundSelectedOphthalmicAxialLengthSequence,
  '00221250': exports.OphthalmicAxialLengthSelectionMethodCodeSequence,
  '00221255': exports.OpticalSelectedOphthalmicAxialLengthSequence,
  '00221257': exports.SelectedSegmentalOphthalmicAxialLengthSequence,
  '00221260': exports.SelectedTotalOphthalmicAxialLengthSequence,
  '00221262': exports.OphthalmicAxialLengthQualityMetricSequence,
  '00221265': exports.OphthalmicAxialLengthQualityMetricTypeCodeSequence,
  '00221273': exports.OphthalmicAxialLengthQualityMetricTypeDescription,
  '00221300': exports.IntraocularLensCalculationsRightEyeSequence,
  '00221310': exports.IntraocularLensCalculationsLeftEyeSequence,
  '00221330': exports.ReferencedOphthalmicAxialLengthMeasurementQCImageSequence,
  '00221415': exports.OphthalmicMappingDeviceType,
  '00221420': exports.AcquisitionMethodCodeSequence,
  '00221423': exports.AcquisitionMethodAlgorithmSequence,
  '00221436': exports.OphthalmicThicknessMapTypeCodeSequence,
  '00221443': exports.OphthalmicThicknessMappingNormalsSequence,
  '00221445': exports.RetinalThicknessDefinitionCodeSequence,
  '00221450': exports.PixelValueMappingToCodedConceptSequence,
  '00221452': exports.MappedPixelValue,
  '00221454': exports.PixelValueMappingExplanation,
  '00221458': exports.OphthalmicThicknessMapQualityThresholdSequence,
  '00221460': exports.OphthalmicThicknessMapThresholdQualityRating,
  '00221463': exports.AnatomicStructureReferencePoint,
  '00221465': exports.RegistrationToLocalizerSequence,
  '00221466': exports.RegisteredLocalizerUnits,
  '00221467': exports.RegisteredLocalizerTopLeftHandCorner,
  '00221468': exports.RegisteredLocalizerBottomRightHandCorner,
  '00221470': exports.OphthalmicThicknessMapQualityRatingSequence,
  '00221472': exports.RelevantOPTAttributesSequence,
  '00240010': exports.VisualFieldHorizontalExtent,
  '00240011': exports.VisualFieldVerticalExtent,
  '00240012': exports.VisualFieldShape,
  '00240016': exports.ScreeningTestModeCodeSequence,
  '00240018': exports.MaximumStimulusLuminance,
  '00240020': exports.BackgroundLuminance,
  '00240021': exports.StimulusColorCodeSequence,
  '00240024': exports.BackgroundIlluminationColorCodeSequence,
  '00240025': exports.StimulusArea,
  '00240028': exports.StimulusPresentationTime,
  '00240032': exports.FixationSequence,
  '00240033': exports.FixationMonitoringCodeSequence,
  '00240034': exports.VisualFieldCatchTrialSequence,
  '00240035': exports.FixationCheckedQuantity,
  '00240036': exports.PatientNotProperlyFixatedQuantity,
  '00240037': exports.PresentedVisualStimuliDataFlag,
  '00240038': exports.NumberOfVisualStimuli,
  '00240039': exports.ExcessiveFixationLossesDataFlag,
  '00240040': exports.ExcessiveFixationLosses,
  '00240042': exports.StimuliRetestingQuantity,
  '00240044': exports.CommentsOnPatientPerformanceOfVisualField,
  '00240045': exports.FalseNegativesEstimateFlag,
  '00240046': exports.FalseNegativesEstimate,
  '00240048': exports.NegativeCatchTrialsQuantity,
  '00240050': exports.FalseNegativesQuantity,
  '00240051': exports.ExcessiveFalseNegativesDataFlag,
  '00240052': exports.ExcessiveFalseNegatives,
  '00240053': exports.FalsePositivesEstimateFlag,
  '00240054': exports.FalsePositivesEstimate,
  '00240055': exports.CatchTrialsDataFlag,
  '00240056': exports.PositiveCatchTrialsQuantity,
  '00240057': exports.TestPointNormalsDataFlag,
  '00240058': exports.TestPointNormalsSequence,
  '00240059': exports.GlobalDeviationProbabilityNormalsFlag,
  '00240060': exports.FalsePositivesQuantity,
  '00240061': exports.ExcessiveFalsePositivesDataFlag,
  '00240062': exports.ExcessiveFalsePositives,
  '00240063': exports.VisualFieldTestNormalsFlag,
  '00240064': exports.ResultsNormalsSequence,
  '00240065': exports.AgeCorrectedSensitivityDeviationAlgorithmSequence,
  '00240066': exports.GlobalDeviationFromNormal,
  '00240067': exports.GeneralizedDefectSensitivityDeviationAlgorithmSequence,
  '00240068': exports.LocalizedDeviationFromNormal,
  '00240069': exports.PatientReliabilityIndicator,
  '00240070': exports.VisualFieldMeanSensitivity,
  '00240071': exports.GlobalDeviationProbability,
  '00240072': exports.LocalDeviationProbabilityNormalsFlag,
  '00240073': exports.LocalizedDeviationProbability,
  '00240074': exports.ShortTermFluctuationCalculated,
  '00240075': exports.ShortTermFluctuation,
  '00240076': exports.ShortTermFluctuationProbabilityCalculated,
  '00240077': exports.ShortTermFluctuationProbability,
  '00240078': exports.CorrectedLocalizedDeviationFromNormalCalculated,
  '00240079': exports.CorrectedLocalizedDeviationFromNormal,
  '00240080': exports.CorrectedLocalizedDeviationFromNormalProbabilityCalculated,
  '00240081': exports.CorrectedLocalizedDeviationFromNormalProbability,
  '00240083': exports.GlobalDeviationProbabilitySequence,
  '00240085': exports.LocalizedDeviationProbabilitySequence,
  '00240086': exports.FovealSensitivityMeasured,
  '00240087': exports.FovealSensitivity,
  '00240088': exports.VisualFieldTestDuration,
  '00240089': exports.VisualFieldTestPointSequence,
  '00240090': exports.VisualFieldTestPointXCoordinate,
  '00240091': exports.VisualFieldTestPointYCoordinate,
  '00240092': exports.AgeCorrectedSensitivityDeviationValue,
  '00240093': exports.StimulusResults,
  '00240094': exports.SensitivityValue,
  '00240095': exports.RetestStimulusSeen,
  '00240096': exports.RetestSensitivityValue,
  '00240097': exports.VisualFieldTestPointNormalsSequence,
  '00240098': exports.QuantifiedDefect,
  '00240100': exports.AgeCorrectedSensitivityDeviationProbabilityValue,
  '00240102': exports.GeneralizedDefectCorrectedSensitivityDeviationFlag,
  '00240103': exports.GeneralizedDefectCorrectedSensitivityDeviationValue,
  '00240104': exports.GeneralizedDefectCorrectedSensitivityDeviationProbabilityValue,
  '00240105': exports.MinimumSensitivityValue,
  '00240106': exports.BlindSpotLocalized,
  '00240107': exports.BlindSpotXCoordinate,
  '00240108': exports.BlindSpotYCoordinate,
  '00240110': exports.VisualAcuityMeasurementSequence,
  '00240112': exports.RefractiveParametersUsedOnPatientSequence,
  '00240113': exports.MeasurementLaterality,
  '00240114': exports.OphthalmicPatientClinicalInformationLeftEyeSequence,
  '00240115': exports.OphthalmicPatientClinicalInformationRightEyeSequence,
  '00240117': exports.FovealPointNormativeDataFlag,
  '00240118': exports.FovealPointProbabilityValue,
  '00240120': exports.ScreeningBaselineMeasured,
  '00240122': exports.ScreeningBaselineMeasuredSequence,
  '00240124': exports.ScreeningBaselineType,
  '00240126': exports.ScreeningBaselineValue,
  '00240202': exports.AlgorithmSource,
  '00240306': exports.DataSetName,
  '00240307': exports.DataSetVersion,
  '00240308': exports.DataSetSource,
  '00240309': exports.DataSetDescription,
  '00240317': exports.VisualFieldTestReliabilityGlobalIndexSequence,
  '00240320': exports.VisualFieldGlobalResultsIndexSequence,
  '00240325': exports.DataObservationSequence,
  '00240338': exports.IndexNormalsFlag,
  '00240341': exports.IndexProbability,
  '00240344': exports.IndexProbabilitySequence,
  '00280002': exports.SamplesPerPixel,
  '00280003': exports.SamplesPerPixelUsed,
  '00280004': exports.PhotometricInterpretation,
  '00280005': exports.ImageDimensions,
  '00280006': exports.PlanarConfiguration,
  '00280008': exports.NumberOfFrames,
  '00280009': exports.FrameIncrementPointer,
  '0028000a': exports.FrameDimensionPointer,
  '00280010': exports.Rows,
  '00280011': exports.Columns,
  '00280012': exports.Planes,
  '00280014': exports.UltrasoundColorDataPresent,
  '00280030': exports.PixelSpacing,
  '00280031': exports.ZoomFactor,
  '00280032': exports.ZoomCenter,
  '00280034': exports.PixelAspectRatio,
  '00280040': exports.ImageFormat,
  '00280050': exports.ManipulatedImage,
  '00280051': exports.CorrectedImage,
  '0028005f': exports.CompressionRecognitionCode,
  '00280060': exports.CompressionCode,
  '00280061': exports.CompressionOriginator,
  '00280062': exports.CompressionLabel,
  '00280063': exports.CompressionDescription,
  '00280065': exports.CompressionSequence,
  '00280066': exports.CompressionStepPointers,
  '00280068': exports.RepeatInterval,
  '00280069': exports.BitsGrouped,
  '00280070': exports.PerimeterTable,
  '00280071': exports.PerimeterValue,
  '00280080': exports.PredictorRows,
  '00280081': exports.PredictorColumns,
  '00280082': exports.PredictorConstants,
  '00280090': exports.BlockedPixels,
  '00280091': exports.BlockRows,
  '00280092': exports.BlockColumns,
  '00280093': exports.RowOverlap,
  '00280094': exports.ColumnOverlap,
  '00280100': exports.BitsAllocated,
  '00280101': exports.BitsStored,
  '00280102': exports.HighBit,
  '00280103': exports.PixelRepresentation,
  '00280104': exports.SmallestValidPixelValue,
  '00280105': exports.LargestValidPixelValue,
  '00280106': exports.SmallestImagePixelValue,
  '00280107': exports.LargestImagePixelValue,
  '00280108': exports.SmallestPixelValueInSeries,
  '00280109': exports.LargestPixelValueInSeries,
  '00280110': exports.SmallestImagePixelValueInPlane,
  '00280111': exports.LargestImagePixelValueInPlane,
  '00280120': exports.PixelPaddingValue,
  '00280121': exports.PixelPaddingRangeLimit,
  '00280200': exports.ImageLocation,
  '00280300': exports.QualityControlImage,
  '00280301': exports.BurnedInAnnotation,
  '00280302': exports.RecognizableVisualFeatures,
  '00280303': exports.LongitudinalTemporalInformationModified,
  '00280304': exports.ReferencedColorPaletteInstanceUID,
  '00280400': exports.TransformLabel,
  '00280401': exports.TransformVersionNumber,
  '00280402': exports.NumberOfTransformSteps,
  '00280403': exports.SequenceOfCompressedData,
  '00280404': exports.DetailsOfCoefficients,
  '00280400': exports.RowsForNthOrderCoefficients,
  '00280401': exports.ColumnsForNthOrderCoefficients,
  '00280402': exports.CoefficientCoding,
  '00280403': exports.CoefficientCodingPointers,
  '00280700': exports.DCTLabel,
  '00280701': exports.DataBlockDescription,
  '00280702': exports.DataBlock,
  '00280710': exports.NormalizationFactorFormat,
  '00280720': exports.ZonalMapNumberFormat,
  '00280721': exports.ZonalMapLocation,
  '00280722': exports.ZonalMapFormat,
  '00280730': exports.AdaptiveMapFormat,
  '00280740': exports.CodeNumberFormat,
  '00280800': exports.CodeLabel,
  '00280802': exports.NumberOfTables,
  '00280803': exports.CodeTableLocation,
  '00280804': exports.BitsForCodeWord,
  '00280808': exports.ImageDataLocation,
  '00280a02': exports.PixelSpacingCalibrationType,
  '00280a04': exports.PixelSpacingCalibrationDescription,
  '00281040': exports.PixelIntensityRelationship,
  '00281041': exports.PixelIntensityRelationshipSign,
  '00281050': exports.WindowCenter,
  '00281051': exports.WindowWidth,
  '00281052': exports.RescaleIntercept,
  '00281053': exports.RescaleSlope,
  '00281054': exports.RescaleType,
  '00281055': exports.WindowCenterWidthExplanation,
  '00281056': exports.VOILUTFunction,
  '00281080': exports.GrayScale,
  '00281090': exports.RecommendedViewingMode,
  '00281100': exports.GrayLookupTableDescriptor,
  '00281101': exports.RedPaletteColorLookupTableDescriptor,
  '00281102': exports.GreenPaletteColorLookupTableDescriptor,
  '00281103': exports.BluePaletteColorLookupTableDescriptor,
  '00281104': exports.AlphaPaletteColorLookupTableDescriptor,
  '00281111': exports.LargeRedPaletteColorLookupTableDescriptor,
  '00281112': exports.LargeGreenPaletteColorLookupTableDescriptor,
  '00281113': exports.LargeBluePaletteColorLookupTableDescriptor,
  '00281199': exports.PaletteColorLookupTableUID,
  '00281200': exports.GrayLookupTableData,
  '00281201': exports.RedPaletteColorLookupTableData,
  '00281202': exports.GreenPaletteColorLookupTableData,
  '00281203': exports.BluePaletteColorLookupTableData,
  '00281204': exports.AlphaPaletteColorLookupTableData,
  '00281211': exports.LargeRedPaletteColorLookupTableData,
  '00281212': exports.LargeGreenPaletteColorLookupTableData,
  '00281213': exports.LargeBluePaletteColorLookupTableData,
  '00281214': exports.LargePaletteColorLookupTableUID,
  '00281221': exports.SegmentedRedPaletteColorLookupTableData,
  '00281222': exports.SegmentedGreenPaletteColorLookupTableData,
  '00281223': exports.SegmentedBluePaletteColorLookupTableData,
  '00281300': exports.BreastImplantPresent,
  '00281350': exports.PartialView,
  '00281351': exports.PartialViewDescription,
  '00281352': exports.PartialViewCodeSequence,
  '0028135a': exports.SpatialLocationsPreserved,
  '00281401': exports.DataFrameAssignmentSequence,
  '00281402': exports.DataPathAssignment,
  '00281403': exports.BitsMappedToColorLookupTable,
  '00281404': exports.BlendingLUT1Sequence,
  '00281405': exports.BlendingLUT1TransferFunction,
  '00281406': exports.BlendingWeightConstant,
  '00281407': exports.BlendingLookupTableDescriptor,
  '00281408': exports.BlendingLookupTableData,
  '0028140b': exports.EnhancedPaletteColorLookupTableSequence,
  '0028140c': exports.BlendingLUT2Sequence,
  '0028140d': exports.BlendingLUT2TransferFunction,
  '0028140e': exports.DataPathID,
  '0028140f': exports.RGBLUTTransferFunction,
  '00281410': exports.AlphaLUTTransferFunction,
  '00282000': exports.ICCProfile,
  '00282110': exports.LossyImageCompression,
  '00282112': exports.LossyImageCompressionRatio,
  '00282114': exports.LossyImageCompressionMethod,
  '00283000': exports.ModalityLUTSequence,
  '00283002': exports.LUTDescriptor,
  '00283003': exports.LUTExplanation,
  '00283004': exports.ModalityLUTType,
  '00283006': exports.LUTData,
  '00283010': exports.VOILUTSequence,
  '00283110': exports.SoftcopyVOILUTSequence,
  '00284000': exports.ImagePresentationComments,
  '00285000': exports.BiPlaneAcquisitionSequence,
  '00286010': exports.RepresentativeFrameNumber,
  '00286020': exports.FrameNumbersOfInterest,
  '00286022': exports.FrameOfInterestDescription,
  '00286023': exports.FrameOfInterestType,
  '00286030': exports.MaskPointers,
  '00286040': exports.RWavePointer,
  '00286100': exports.MaskSubtractionSequence,
  '00286101': exports.MaskOperation,
  '00286102': exports.ApplicableFrameRange,
  '00286110': exports.MaskFrameNumbers,
  '00286112': exports.ContrastFrameAveraging,
  '00286114': exports.MaskSubPixelShift,
  '00286120': exports.TIDOffset,
  '00286190': exports.MaskOperationExplanation,
  '00287000': exports.EquipmentAdministratorSequence,
  '00287001': exports.NumberOfDisplaySubsystems,
  '00287002': exports.CurrentConfigurationID,
  '00287003': exports.DisplaySubsystemID,
  '00287004': exports.DisplaySubsystemName,
  '00287005': exports.DisplaySubsystemDescription,
  '00287006': exports.SystemStatus,
  '00287007': exports.SystemStatusComment,
  '00287008': exports.TargetLuminanceCharacteristicsSequence,
  '00287009': exports.LuminanceCharacteristicsID,
  '0028700a': exports.DisplaySubsystemConfigurationSequence,
  '0028700b': exports.ConfigurationID,
  '0028700c': exports.ConfigurationName,
  '0028700d': exports.ConfigurationDescription,
  '0028700e': exports.ReferencedTargetLuminanceCharacteristicsID,
  '0028700f': exports.QAResultsSequence,
  '00287010': exports.DisplaySubsystemQAResultsSequence,
  '00287011': exports.ConfigurationQAResultsSequence,
  '00287012': exports.MeasurementEquipmentSequence,
  '00287013': exports.MeasurementFunctions,
  '00287014': exports.MeasurementEquipmentType,
  '00287015': exports.VisualEvaluationResultSequence,
  '00287016': exports.DisplayCalibrationResultSequence,
  '00287017': exports.DDLValue,
  '00287018': exports.CIExyWhitePoint,
  '00287019': exports.DisplayFunctionType,
  '0028701a': exports.GammaValue,
  '0028701b': exports.NumberOfLuminancePoints,
  '0028701c': exports.LuminanceResponseSequence,
  '0028701d': exports.TargetMinimumLuminance,
  '0028701e': exports.TargetMaximumLuminance,
  '0028701f': exports.LuminanceValue,
  '00287020': exports.LuminanceResponseDescription,
  '00287021': exports.WhitePointFlag,
  '00287022': exports.DisplayDeviceTypeCodeSequence,
  '00287023': exports.DisplaySubsystemSequence,
  '00287024': exports.LuminanceResultSequence,
  '00287025': exports.AmbientLightValueSource,
  '00287026': exports.MeasuredCharacteristics,
  '00287027': exports.LuminanceUniformityResultSequence,
  '00287028': exports.VisualEvaluationTestSequence,
  '00287029': exports.TestResult,
  '0028702a': exports.TestResultComment,
  '0028702b': exports.TestImageValidation,
  '0028702c': exports.TestPatternCodeSequence,
  '0028702d': exports.MeasurementPatternCodeSequence,
  '0028702e': exports.VisualEvaluationMethodCodeSequence,
  '00287fe0': exports.PixelDataProviderURL,
  '00289001': exports.DataPointRows,
  '00289002': exports.DataPointColumns,
  '00289003': exports.SignalDomainColumns,
  '00289099': exports.LargestMonochromePixelValue,
  '00289108': exports.DataRepresentation,
  '00289110': exports.PixelMeasuresSequence,
  '00289132': exports.FrameVOILUTSequence,
  '00289145': exports.PixelValueTransformationSequence,
  '00289235': exports.SignalDomainRows,
  '00289411': exports.DisplayFilterPercentage,
  '00289415': exports.FramePixelShiftSequence,
  '00289416': exports.SubtractionItemID,
  '00289422': exports.PixelIntensityRelationshipLUTSequence,
  '00289443': exports.FramePixelDataPropertiesSequence,
  '00289444': exports.GeometricalProperties,
  '00289445': exports.GeometricMaximumDistortion,
  '00289446': exports.ImageProcessingApplied,
  '00289454': exports.MaskSelectionMode,
  '00289474': exports.LUTFunction,
  '00289478': exports.MaskVisibilityPercentage,
  '00289501': exports.PixelShiftSequence,
  '00289502': exports.RegionPixelShiftSequence,
  '00289503': exports.VerticesOfTheRegion,
  '00289505': exports.MultiFramePresentationSequence,
  '00289506': exports.PixelShiftFrameRange,
  '00289507': exports.LUTFrameRange,
  '00289520': exports.ImageToEquipmentMappingMatrix,
  '00289537': exports.EquipmentCoordinateSystemIdentification,
  '0032000a': exports.StudyStatusID,
  '0032000c': exports.StudyPriorityID,
  '00320012': exports.StudyIDIssuer,
  '00320032': exports.StudyVerifiedDate,
  '00320033': exports.StudyVerifiedTime,
  '00320034': exports.StudyReadDate,
  '00320035': exports.StudyReadTime,
  '00321000': exports.ScheduledStudyStartDate,
  '00321001': exports.ScheduledStudyStartTime,
  '00321010': exports.ScheduledStudyStopDate,
  '00321011': exports.ScheduledStudyStopTime,
  '00321020': exports.ScheduledStudyLocation,
  '00321021': exports.ScheduledStudyLocationAETitle,
  '00321030': exports.ReasonForStudy,
  '00321031': exports.RequestingPhysicianIdentificationSequence,
  '00321032': exports.RequestingPhysician,
  '00321033': exports.RequestingService,
  '00321034': exports.RequestingServiceCodeSequence,
  '00321040': exports.StudyArrivalDate,
  '00321041': exports.StudyArrivalTime,
  '00321050': exports.StudyCompletionDate,
  '00321051': exports.StudyCompletionTime,
  '00321055': exports.StudyComponentStatusID,
  '00321060': exports.RequestedProcedureDescription,
  '00321064': exports.RequestedProcedureCodeSequence,
  '00321070': exports.RequestedContrastAgent,
  '00324000': exports.StudyComments,
  '00380004': exports.ReferencedPatientAliasSequence,
  '00380008': exports.VisitStatusID,
  '00380010': exports.AdmissionID,
  '00380011': exports.IssuerOfAdmissionID,
  '00380014': exports.IssuerOfAdmissionIDSequence,
  '00380016': exports.RouteOfAdmissions,
  '0038001a': exports.ScheduledAdmissionDate,
  '0038001b': exports.ScheduledAdmissionTime,
  '0038001c': exports.ScheduledDischargeDate,
  '0038001d': exports.ScheduledDischargeTime,
  '0038001e': exports.ScheduledPatientInstitutionResidence,
  '00380020': exports.AdmittingDate,
  '00380021': exports.AdmittingTime,
  '00380030': exports.DischargeDate,
  '00380032': exports.DischargeTime,
  '00380040': exports.DischargeDiagnosisDescription,
  '00380044': exports.DischargeDiagnosisCodeSequence,
  '00380050': exports.SpecialNeeds,
  '00380060': exports.ServiceEpisodeID,
  '00380061': exports.IssuerOfServiceEpisodeID,
  '00380062': exports.ServiceEpisodeDescription,
  '00380064': exports.IssuerOfServiceEpisodeIDSequence,
  '00380100': exports.PertinentDocumentsSequence,
  '00380300': exports.CurrentPatientLocation,
  '00380400': exports.PatientInstitutionResidence,
  '00380500': exports.PatientState,
  '00380502': exports.PatientClinicalTrialParticipationSequence,
  '00384000': exports.VisitComments,
  '003a0004': exports.WaveformOriginality,
  '003a0005': exports.NumberOfWaveformChannels,
  '003a0010': exports.NumberOfWaveformSamples,
  '003a001a': exports.SamplingFrequency,
  '003a0020': exports.MultiplexGroupLabel,
  '003a0200': exports.ChannelDefinitionSequence,
  '003a0202': exports.WaveformChannelNumber,
  '003a0203': exports.ChannelLabel,
  '003a0205': exports.ChannelStatus,
  '003a0208': exports.ChannelSourceSequence,
  '003a0209': exports.ChannelSourceModifiersSequence,
  '003a020a': exports.SourceWaveformSequence,
  '003a020c': exports.ChannelDerivationDescription,
  '003a0210': exports.ChannelSensitivity,
  '003a0211': exports.ChannelSensitivityUnitsSequence,
  '003a0212': exports.ChannelSensitivityCorrectionFactor,
  '003a0213': exports.ChannelBaseline,
  '003a0214': exports.ChannelTimeSkew,
  '003a0215': exports.ChannelSampleSkew,
  '003a0218': exports.ChannelOffset,
  '003a021a': exports.WaveformBitsStored,
  '003a0220': exports.FilterLowFrequency,
  '003a0221': exports.FilterHighFrequency,
  '003a0222': exports.NotchFilterFrequency,
  '003a0223': exports.NotchFilterBandwidth,
  '003a0230': exports.WaveformDataDisplayScale,
  '003a0231': exports.WaveformDisplayBackgroundCIELabValue,
  '003a0240': exports.WaveformPresentationGroupSequence,
  '003a0241': exports.PresentationGroupNumber,
  '003a0242': exports.ChannelDisplaySequence,
  '003a0244': exports.ChannelRecommendedDisplayCIELabValue,
  '003a0245': exports.ChannelPosition,
  '003a0246': exports.DisplayShadingFlag,
  '003a0247': exports.FractionalChannelDisplayScale,
  '003a0248': exports.AbsoluteChannelDisplayScale,
  '003a0300': exports.MultiplexedAudioChannelsDescriptionCodeSequence,
  '003a0301': exports.ChannelIdentificationCode,
  '003a0302': exports.ChannelMode,
  '00400001': exports.ScheduledStationAETitle,
  '00400002': exports.ScheduledProcedureStepStartDate,
  '00400003': exports.ScheduledProcedureStepStartTime,
  '00400004': exports.ScheduledProcedureStepEndDate,
  '00400005': exports.ScheduledProcedureStepEndTime,
  '00400006': exports.ScheduledPerformingPhysicianName,
  '00400007': exports.ScheduledProcedureStepDescription,
  '00400008': exports.ScheduledProtocolCodeSequence,
  '00400009': exports.ScheduledProcedureStepID,
  '0040000a': exports.StageCodeSequence,
  '0040000b': exports.ScheduledPerformingPhysicianIdentificationSequence,
  '00400010': exports.ScheduledStationName,
  '00400011': exports.ScheduledProcedureStepLocation,
  '00400012': exports.PreMedication,
  '00400020': exports.ScheduledProcedureStepStatus,
  '00400026': exports.OrderPlacerIdentifierSequence,
  '00400027': exports.OrderFillerIdentifierSequence,
  '00400031': exports.LocalNamespaceEntityID,
  '00400032': exports.UniversalEntityID,
  '00400033': exports.UniversalEntityIDType,
  '00400035': exports.IdentifierTypeCode,
  '00400036': exports.AssigningFacilitySequence,
  '00400039': exports.AssigningJurisdictionCodeSequence,
  '0040003a': exports.AssigningAgencyOrDepartmentCodeSequence,
  '00400100': exports.ScheduledProcedureStepSequence,
  '00400220': exports.ReferencedNonImageCompositeSOPInstanceSequence,
  '00400241': exports.PerformedStationAETitle,
  '00400242': exports.PerformedStationName,
  '00400243': exports.PerformedLocation,
  '00400244': exports.PerformedProcedureStepStartDate,
  '00400245': exports.PerformedProcedureStepStartTime,
  '00400250': exports.PerformedProcedureStepEndDate,
  '00400251': exports.PerformedProcedureStepEndTime,
  '00400252': exports.PerformedProcedureStepStatus,
  '00400253': exports.PerformedProcedureStepID,
  '00400254': exports.PerformedProcedureStepDescription,
  '00400255': exports.PerformedProcedureTypeDescription,
  '00400260': exports.PerformedProtocolCodeSequence,
  '00400261': exports.PerformedProtocolType,
  '00400270': exports.ScheduledStepAttributesSequence,
  '00400275': exports.RequestAttributesSequence,
  '00400280': exports.CommentsOnThePerformedProcedureStep,
  '00400281': exports.PerformedProcedureStepDiscontinuationReasonCodeSequence,
  '00400293': exports.QuantitySequence,
  '00400294': exports.Quantity,
  '00400295': exports.MeasuringUnitsSequence,
  '00400296': exports.BillingItemSequence,
  '00400300': exports.TotalTimeOfFluoroscopy,
  '00400301': exports.TotalNumberOfExposures,
  '00400302': exports.EntranceDose,
  '00400303': exports.ExposedArea,
  '00400306': exports.DistanceSourceToEntrance,
  '00400307': exports.DistanceSourceToSupport,
  '0040030e': exports.ExposureDoseSequence,
  '00400310': exports.CommentsOnRadiationDose,
  '00400312': exports.XRayOutput,
  '00400314': exports.HalfValueLayer,
  '00400316': exports.OrganDose,
  '00400318': exports.OrganExposed,
  '00400320': exports.BillingProcedureStepSequence,
  '00400321': exports.FilmConsumptionSequence,
  '00400324': exports.BillingSuppliesAndDevicesSequence,
  '00400330': exports.ReferencedProcedureStepSequence,
  '00400340': exports.PerformedSeriesSequence,
  '00400400': exports.CommentsOnTheScheduledProcedureStep,
  '00400440': exports.ProtocolContextSequence,
  '00400441': exports.ContentItemModifierSequence,
  '00400500': exports.ScheduledSpecimenSequence,
  '0040050a': exports.SpecimenAccessionNumber,
  '00400512': exports.ContainerIdentifier,
  '00400513': exports.IssuerOfTheContainerIdentifierSequence,
  '00400515': exports.AlternateContainerIdentifierSequence,
  '00400518': exports.ContainerTypeCodeSequence,
  '0040051a': exports.ContainerDescription,
  '00400520': exports.ContainerComponentSequence,
  '00400550': exports.SpecimenSequence,
  '00400551': exports.SpecimenIdentifier,
  '00400552': exports.SpecimenDescriptionSequenceTrial,
  '00400553': exports.SpecimenDescriptionTrial,
  '00400554': exports.SpecimenUID,
  '00400555': exports.AcquisitionContextSequence,
  '00400556': exports.AcquisitionContextDescription,
  '0040059a': exports.SpecimenTypeCodeSequence,
  '00400560': exports.SpecimenDescriptionSequence,
  '00400562': exports.IssuerOfTheSpecimenIdentifierSequence,
  '00400600': exports.SpecimenShortDescription,
  '00400602': exports.SpecimenDetailedDescription,
  '00400610': exports.SpecimenPreparationSequence,
  '00400612': exports.SpecimenPreparationStepContentItemSequence,
  '00400620': exports.SpecimenLocalizationContentItemSequence,
  '004006fa': exports.SlideIdentifier,
  '0040071a': exports.ImageCenterPointCoordinatesSequence,
  '0040072a': exports.XOffsetInSlideCoordinateSystem,
  '0040073a': exports.YOffsetInSlideCoordinateSystem,
  '0040074a': exports.ZOffsetInSlideCoordinateSystem,
  '004008d8': exports.PixelSpacingSequence,
  '004008da': exports.CoordinateSystemAxisCodeSequence,
  '004008ea': exports.MeasurementUnitsCodeSequence,
  '004009f8': exports.VitalStainCodeSequenceTrial,
  '00401001': exports.RequestedProcedureID,
  '00401002': exports.ReasonForTheRequestedProcedure,
  '00401003': exports.RequestedProcedurePriority,
  '00401004': exports.PatientTransportArrangements,
  '00401005': exports.RequestedProcedureLocation,
  '00401006': exports.PlacerOrderNumberProcedure,
  '00401007': exports.FillerOrderNumberProcedure,
  '00401008': exports.ConfidentialityCode,
  '00401009': exports.ReportingPriority,
  '0040100a': exports.ReasonForRequestedProcedureCodeSequence,
  '00401010': exports.NamesOfIntendedRecipientsOfResults,
  '00401011': exports.IntendedRecipientsOfResultsIdentificationSequence,
  '00401012': exports.ReasonForPerformedProcedureCodeSequence,
  '00401060': exports.RequestedProcedureDescriptionTrial,
  '00401101': exports.PersonIdentificationCodeSequence,
  '00401102': exports.PersonAddress,
  '00401103': exports.PersonTelephoneNumbers,
  '00401400': exports.RequestedProcedureComments,
  '00402001': exports.ReasonForTheImagingServiceRequest,
  '00402004': exports.IssueDateOfImagingServiceRequest,
  '00402005': exports.IssueTimeOfImagingServiceRequest,
  '00402006': exports.PlacerOrderNumberImagingServiceRequestRetired,
  '00402007': exports.FillerOrderNumberImagingServiceRequestRetired,
  '00402008': exports.OrderEnteredBy,
  '00402009': exports.OrderEntererLocation,
  '00402010': exports.OrderCallbackPhoneNumber,
  '00402016': exports.PlacerOrderNumberImagingServiceRequest,
  '00402017': exports.FillerOrderNumberImagingServiceRequest,
  '00402400': exports.ImagingServiceRequestComments,
  '00403001': exports.ConfidentialityConstraintOnPatientDataDescription,
  '00404001': exports.GeneralPurposeScheduledProcedureStepStatus,
  '00404002': exports.GeneralPurposePerformedProcedureStepStatus,
  '00404003': exports.GeneralPurposeScheduledProcedureStepPriority,
  '00404004': exports.ScheduledProcessingApplicationsCodeSequence,
  '00404005': exports.ScheduledProcedureStepStartDateTime,
  '00404006': exports.MultipleCopiesFlag,
  '00404007': exports.PerformedProcessingApplicationsCodeSequence,
  '00404009': exports.HumanPerformerCodeSequence,
  '00404010': exports.ScheduledProcedureStepModificationDateTime,
  '00404011': exports.ExpectedCompletionDateTime,
  '00404015': exports.ResultingGeneralPurposePerformedProcedureStepsSequence,
  '00404016': exports.ReferencedGeneralPurposeScheduledProcedureStepSequence,
  '00404018': exports.ScheduledWorkitemCodeSequence,
  '00404019': exports.PerformedWorkitemCodeSequence,
  '00404020': exports.InputAvailabilityFlag,
  '00404021': exports.InputInformationSequence,
  '00404022': exports.RelevantInformationSequence,
  '00404023': exports.ReferencedGeneralPurposeScheduledProcedureStepTransactionUID,
  '00404025': exports.ScheduledStationNameCodeSequence,
  '00404026': exports.ScheduledStationClassCodeSequence,
  '00404027': exports.ScheduledStationGeographicLocationCodeSequence,
  '00404028': exports.PerformedStationNameCodeSequence,
  '00404029': exports.PerformedStationClassCodeSequence,
  '00404030': exports.PerformedStationGeographicLocationCodeSequence,
  '00404031': exports.RequestedSubsequentWorkitemCodeSequence,
  '00404032': exports.NonDICOMOutputCodeSequence,
  '00404033': exports.OutputInformationSequence,
  '00404034': exports.ScheduledHumanPerformersSequence,
  '00404035': exports.ActualHumanPerformersSequence,
  '00404036': exports.HumanPerformerOrganization,
  '00404037': exports.HumanPerformerName,
  '00404040': exports.RawDataHandling,
  '00404041': exports.InputReadinessState,
  '00404050': exports.PerformedProcedureStepStartDateTime,
  '00404051': exports.PerformedProcedureStepEndDateTime,
  '00404052': exports.ProcedureStepCancellationDateTime,
  '00408302': exports.EntranceDoseInmGy,
  '00409094': exports.ReferencedImageRealWorldValueMappingSequence,
  '00409096': exports.RealWorldValueMappingSequence,
  '00409098': exports.PixelValueMappingCodeSequence,
  '00409210': exports.LUTLabel,
  '00409211': exports.RealWorldValueLastValueMapped,
  '00409212': exports.RealWorldValueLUTData,
  '00409216': exports.RealWorldValueFirstValueMapped,
  '00409224': exports.RealWorldValueIntercept,
  '00409225': exports.RealWorldValueSlope,
  '0040a007': exports.FindingsFlagTrial,
  '0040a010': exports.RelationshipType,
  '0040a020': exports.FindingsSequenceTrial,
  '0040a021': exports.FindingsGroupUIDTrial,
  '0040a022': exports.ReferencedFindingsGroupUIDTrial,
  '0040a023': exports.FindingsGroupRecordingDateTrial,
  '0040a024': exports.FindingsGroupRecordingTimeTrial,
  '0040a026': exports.FindingsSourceCategoryCodeSequenceTrial,
  '0040a027': exports.VerifyingOrganization,
  '0040a028': exports.DocumentingOrganizationIdentifierCodeSequenceTrial,
  '0040a030': exports.VerificationDateTime,
  '0040a032': exports.ObservationDateTime,
  '0040a040': exports.ValueType,
  '0040a043': exports.ConceptNameCodeSequence,
  '0040a047': exports.MeasurementPrecisionDescriptionTrial,
  '0040a050': exports.ContinuityOfContent,
  '0040a057': exports.UrgencyOrPriorityAlertsTrial,
  '0040a060': exports.SequencingIndicatorTrial,
  '0040a066': exports.DocumentIdentifierCodeSequenceTrial,
  '0040a067': exports.DocumentAuthorTrial,
  '0040a068': exports.DocumentAuthorIdentifierCodeSequenceTrial,
  '0040a070': exports.IdentifierCodeSequenceTrial,
  '0040a073': exports.VerifyingObserverSequence,
  '0040a074': exports.ObjectBinaryIdentifierTrial,
  '0040a075': exports.VerifyingObserverName,
  '0040a076': exports.DocumentingObserverIdentifierCodeSequenceTrial,
  '0040a078': exports.AuthorObserverSequence,
  '0040a07a': exports.ParticipantSequence,
  '0040a07c': exports.CustodialOrganizationSequence,
  '0040a080': exports.ParticipationType,
  '0040a082': exports.ParticipationDateTime,
  '0040a084': exports.ObserverType,
  '0040a085': exports.ProcedureIdentifierCodeSequenceTrial,
  '0040a088': exports.VerifyingObserverIdentificationCodeSequence,
  '0040a089': exports.ObjectDirectoryBinaryIdentifierTrial,
  '0040a090': exports.EquivalentCDADocumentSequence,
  '0040a0b0': exports.ReferencedWaveformChannels,
  '0040a110': exports.DateOfDocumentOrVerbalTransactionTrial,
  '0040a112': exports.TimeOfDocumentCreationOrVerbalTransactionTrial,
  '0040a120': exports.DateTime,
  '0040a121': exports.Date,
  '0040a122': exports.Time,
  '0040a123': exports.PersonName,
  '0040a124': exports.UID,
  '0040a125': exports.ReportStatusIDTrial,
  '0040a130': exports.TemporalRangeType,
  '0040a132': exports.ReferencedSamplePositions,
  '0040a136': exports.ReferencedFrameNumbers,
  '0040a138': exports.ReferencedTimeOffsets,
  '0040a13a': exports.ReferencedDateTime,
  '0040a160': exports.TextValue,
  '0040a161': exports.FloatingPointValue,
  '0040a162': exports.RationalNumeratorValue,
  '0040a163': exports.RationalDenominatorValue,
  '0040a167': exports.ObservationCategoryCodeSequenceTrial,
  '0040a168': exports.ConceptCodeSequence,
  '0040a16a': exports.BibliographicCitationTrial,
  '0040a170': exports.PurposeOfReferenceCodeSequence,
  '0040a171': exports.ObservationUID,
  '0040a172': exports.ReferencedObservationUIDTrial,
  '0040a173': exports.ReferencedObservationClassTrial,
  '0040a174': exports.ReferencedObjectObservationClassTrial,
  '0040a180': exports.AnnotationGroupNumber,
  '0040a192': exports.ObservationDateTrial,
  '0040a193': exports.ObservationTimeTrial,
  '0040a194': exports.MeasurementAutomationTrial,
  '0040a195': exports.ModifierCodeSequence,
  '0040a224': exports.IdentificationDescriptionTrial,
  '0040a290': exports.CoordinatesSetGeometricTypeTrial,
  '0040a296': exports.AlgorithmCodeSequenceTrial,
  '0040a297': exports.AlgorithmDescriptionTrial,
  '0040a29a': exports.PixelCoordinatesSetTrial,
  '0040a300': exports.MeasuredValueSequence,
  '0040a301': exports.NumericValueQualifierCodeSequence,
  '0040a307': exports.CurrentObserverTrial,
  '0040a30a': exports.NumericValue,
  '0040a313': exports.ReferencedAccessionSequenceTrial,
  '0040a33a': exports.ReportStatusCommentTrial,
  '0040a340': exports.ProcedureContextSequenceTrial,
  '0040a352': exports.VerbalSourceTrial,
  '0040a353': exports.AddressTrial,
  '0040a354': exports.TelephoneNumberTrial,
  '0040a358': exports.VerbalSourceIdentifierCodeSequenceTrial,
  '0040a360': exports.PredecessorDocumentsSequence,
  '0040a370': exports.ReferencedRequestSequence,
  '0040a372': exports.PerformedProcedureCodeSequence,
  '0040a375': exports.CurrentRequestedProcedureEvidenceSequence,
  '0040a380': exports.ReportDetailSequenceTrial,
  '0040a385': exports.PertinentOtherEvidenceSequence,
  '0040a390': exports.HL7StructuredDocumentReferenceSequence,
  '0040a402': exports.ObservationSubjectUIDTrial,
  '0040a403': exports.ObservationSubjectClassTrial,
  '0040a404': exports.ObservationSubjectTypeCodeSequenceTrial,
  '0040a491': exports.CompletionFlag,
  '0040a492': exports.CompletionFlagDescription,
  '0040a493': exports.VerificationFlag,
  '0040a494': exports.ArchiveRequested,
  '0040a496': exports.PreliminaryFlag,
  '0040a504': exports.ContentTemplateSequence,
  '0040a525': exports.IdenticalDocumentsSequence,
  '0040a600': exports.ObservationSubjectContextFlagTrial,
  '0040a601': exports.ObserverContextFlagTrial,
  '0040a603': exports.ProcedureContextFlagTrial,
  '0040a730': exports.ContentSequence,
  '0040a731': exports.RelationshipSequenceTrial,
  '0040a732': exports.RelationshipTypeCodeSequenceTrial,
  '0040a744': exports.LanguageCodeSequenceTrial,
  '0040a992': exports.UniformResourceLocatorTrial,
  '0040b020': exports.WaveformAnnotationSequence,
  '0040db00': exports.TemplateIdentifier,
  '0040db06': exports.TemplateVersion,
  '0040db07': exports.TemplateLocalVersion,
  '0040db0b': exports.TemplateExtensionFlag,
  '0040db0c': exports.TemplateExtensionOrganizationUID,
  '0040db0d': exports.TemplateExtensionCreatorUID,
  '0040db73': exports.ReferencedContentItemIdentifier,
  '0040e001': exports.HL7InstanceIdentifier,
  '0040e004': exports.HL7DocumentEffectiveTime,
  '0040e006': exports.HL7DocumentTypeCodeSequence,
  '0040e008': exports.DocumentClassCodeSequence,
  '0040e010': exports.RetrieveURI,
  '0040e011': exports.RetrieveLocationUID,
  '0040e020': exports.TypeOfInstances,
  '0040e021': exports.DICOMRetrievalSequence,
  '0040e022': exports.DICOMMediaRetrievalSequence,
  '0040e023': exports.WADORetrievalSequence,
  '0040e024': exports.XDSRetrievalSequence,
  '0040e030': exports.RepositoryUniqueID,
  '0040e031': exports.HomeCommunityID,
  '00420010': exports.DocumentTitle,
  '00420011': exports.EncapsulatedDocument,
  '00420012': exports.MIMETypeOfEncapsulatedDocument,
  '00420013': exports.SourceInstanceSequence,
  '00420014': exports.ListOfMIMETypes,
  '00440001': exports.ProductPackageIdentifier,
  '00440002': exports.SubstanceAdministrationApproval,
  '00440003': exports.ApprovalStatusFurtherDescription,
  '00440004': exports.ApprovalStatusDateTime,
  '00440007': exports.ProductTypeCodeSequence,
  '00440008': exports.ProductName,
  '00440009': exports.ProductDescription,
  '0044000a': exports.ProductLotIdentifier,
  '0044000b': exports.ProductExpirationDateTime,
  '00440010': exports.SubstanceAdministrationDateTime,
  '00440011': exports.SubstanceAdministrationNotes,
  '00440012': exports.SubstanceAdministrationDeviceID,
  '00440013': exports.ProductParameterSequence,
  '00440019': exports.SubstanceAdministrationParameterSequence,
  '00460012': exports.LensDescription,
  '00460014': exports.RightLensSequence,
  '00460015': exports.LeftLensSequence,
  '00460016': exports.UnspecifiedLateralityLensSequence,
  '00460018': exports.CylinderSequence,
  '00460028': exports.PrismSequence,
  '00460030': exports.HorizontalPrismPower,
  '00460032': exports.HorizontalPrismBase,
  '00460034': exports.VerticalPrismPower,
  '00460036': exports.VerticalPrismBase,
  '00460038': exports.LensSegmentType,
  '00460040': exports.OpticalTransmittance,
  '00460042': exports.ChannelWidth,
  '00460044': exports.PupilSize,
  '00460046': exports.CornealSize,
  '00460050': exports.AutorefractionRightEyeSequence,
  '00460052': exports.AutorefractionLeftEyeSequence,
  '00460060': exports.DistancePupillaryDistance,
  '00460062': exports.NearPupillaryDistance,
  '00460063': exports.IntermediatePupillaryDistance,
  '00460064': exports.OtherPupillaryDistance,
  '00460070': exports.KeratometryRightEyeSequence,
  '00460071': exports.KeratometryLeftEyeSequence,
  '00460074': exports.SteepKeratometricAxisSequence,
  '00460075': exports.RadiusOfCurvature,
  '00460076': exports.KeratometricPower,
  '00460077': exports.KeratometricAxis,
  '00460080': exports.FlatKeratometricAxisSequence,
  '00460092': exports.BackgroundColor,
  '00460094': exports.Optotype,
  '00460095': exports.OptotypePresentation,
  '00460097': exports.SubjectiveRefractionRightEyeSequence,
  '00460098': exports.SubjectiveRefractionLeftEyeSequence,
  '00460100': exports.AddNearSequence,
  '00460101': exports.AddIntermediateSequence,
  '00460102': exports.AddOtherSequence,
  '00460104': exports.AddPower,
  '00460106': exports.ViewingDistance,
  '00460121': exports.VisualAcuityTypeCodeSequence,
  '00460122': exports.VisualAcuityRightEyeSequence,
  '00460123': exports.VisualAcuityLeftEyeSequence,
  '00460124': exports.VisualAcuityBothEyesOpenSequence,
  '00460125': exports.ViewingDistanceType,
  '00460135': exports.VisualAcuityModifiers,
  '00460137': exports.DecimalVisualAcuity,
  '00460139': exports.OptotypeDetailedDefinition,
  '00460145': exports.ReferencedRefractiveMeasurementsSequence,
  '00460146': exports.SpherePower,
  '00460147': exports.CylinderPower,
  '00460201': exports.CornealTopographySurface,
  '00460202': exports.CornealVertexLocation,
  '00460203': exports.PupilCentroidXCoordinate,
  '00460204': exports.PupilCentroidYCoordinate,
  '00460205': exports.EquivalentPupilRadius,
  '00460207': exports.CornealTopographyMapTypeCodeSequence,
  '00460208': exports.VerticesOfTheOutlineOfPupil,
  '00460210': exports.CornealTopographyMappingNormalsSequence,
  '00460211': exports.MaximumCornealCurvatureSequence,
  '00460212': exports.MaximumCornealCurvature,
  '00460213': exports.MaximumCornealCurvatureLocation,
  '00460215': exports.MinimumKeratometricSequence,
  '00460218': exports.SimulatedKeratometricCylinderSequence,
  '00460220': exports.AverageCornealPower,
  '00460224': exports.CornealISValue,
  '00460227': exports.AnalyzedArea,
  '00460230': exports.SurfaceRegularityIndex,
  '00460232': exports.SurfaceAsymmetryIndex,
  '00460234': exports.CornealEccentricityIndex,
  '00460236': exports.KeratoconusPredictionIndex,
  '00460238': exports.DecimalPotentialVisualAcuity,
  '00460242': exports.CornealTopographyMapQualityEvaluation,
  '00460244': exports.SourceImageCornealProcessedDataSequence,
  '00460247': exports.CornealPointLocation,
  '00460248': exports.CornealPointEstimated,
  '00460249': exports.AxialPower,
  '00460250': exports.TangentialPower,
  '00460251': exports.RefractivePower,
  '00460252': exports.RelativeElevation,
  '00460253': exports.CornealWavefront,
  '00480001': exports.ImagedVolumeWidth,
  '00480002': exports.ImagedVolumeHeight,
  '00480003': exports.ImagedVolumeDepth,
  '00480006': exports.TotalPixelMatrixColumns,
  '00480007': exports.TotalPixelMatrixRows,
  '00480008': exports.TotalPixelMatrixOriginSequence,
  '00480010': exports.SpecimenLabelInImage,
  '00480011': exports.FocusMethod,
  '00480012': exports.ExtendedDepthOfField,
  '00480013': exports.NumberOfFocalPlanes,
  '00480014': exports.DistanceBetweenFocalPlanes,
  '00480015': exports.RecommendedAbsentPixelCIELabValue,
  '00480100': exports.IlluminatorTypeCodeSequence,
  '00480102': exports.ImageOrientationSlide,
  '00480105': exports.OpticalPathSequence,
  '00480106': exports.OpticalPathIdentifier,
  '00480107': exports.OpticalPathDescription,
  '00480108': exports.IlluminationColorCodeSequence,
  '00480110': exports.SpecimenReferenceSequence,
  '00480111': exports.CondenserLensPower,
  '00480112': exports.ObjectiveLensPower,
  '00480113': exports.ObjectiveLensNumericalAperture,
  '00480120': exports.PaletteColorLookupTableSequence,
  '00480200': exports.ReferencedImageNavigationSequence,
  '00480201': exports.TopLeftHandCornerOfLocalizerArea,
  '00480202': exports.BottomRightHandCornerOfLocalizerArea,
  '00480207': exports.OpticalPathIdentificationSequence,
  '0048021a': exports.PlanePositionSlideSequence,
  '0048021e': exports.ColumnPositionInTotalImagePixelMatrix,
  '0048021f': exports.RowPositionInTotalImagePixelMatrix,
  '00480301': exports.PixelOriginInterpretation,
  '00500004': exports.CalibrationImage,
  '00500010': exports.DeviceSequence,
  '00500012': exports.ContainerComponentTypeCodeSequence,
  '00500013': exports.ContainerComponentThickness,
  '00500014': exports.DeviceLength,
  '00500015': exports.ContainerComponentWidth,
  '00500016': exports.DeviceDiameter,
  '00500017': exports.DeviceDiameterUnits,
  '00500018': exports.DeviceVolume,
  '00500019': exports.InterMarkerDistance,
  '0050001a': exports.ContainerComponentMaterial,
  '0050001b': exports.ContainerComponentID,
  '0050001c': exports.ContainerComponentLength,
  '0050001d': exports.ContainerComponentDiameter,
  '0050001e': exports.ContainerComponentDescription,
  '00500020': exports.DeviceDescription,
  '00520001': exports.ContrastBolusIngredientPercentByVolume,
  '00520002': exports.OCTFocalDistance,
  '00520003': exports.BeamSpotSize,
  '00520004': exports.EffectiveRefractiveIndex,
  '00520006': exports.OCTAcquisitionDomain,
  '00520007': exports.OCTOpticalCenterWavelength,
  '00520008': exports.AxialResolution,
  '00520009': exports.RangingDepth,
  '00520011': exports.ALineRate,
  '00520012': exports.ALinesPerFrame,
  '00520013': exports.CatheterRotationalRate,
  '00520014': exports.ALinePixelSpacing,
  '00520016': exports.ModeOfPercutaneousAccessSequence,
  '00520025': exports.IntravascularOCTFrameTypeSequence,
  '00520026': exports.OCTZOffsetApplied,
  '00520027': exports.IntravascularFrameContentSequence,
  '00520028': exports.IntravascularLongitudinalDistance,
  '00520029': exports.IntravascularOCTFrameContentSequence,
  '00520030': exports.OCTZOffsetCorrection,
  '00520031': exports.CatheterDirectionOfRotation,
  '00520033': exports.SeamLineLocation,
  '00520034': exports.FirstALineLocation,
  '00520036': exports.SeamLineIndex,
  '00520038': exports.NumberOfPaddedALines,
  '00520039': exports.InterpolationType,
  '0052003a': exports.RefractiveIndexApplied,
  '00540010': exports.EnergyWindowVector,
  '00540011': exports.NumberOfEnergyWindows,
  '00540012': exports.EnergyWindowInformationSequence,
  '00540013': exports.EnergyWindowRangeSequence,
  '00540014': exports.EnergyWindowLowerLimit,
  '00540015': exports.EnergyWindowUpperLimit,
  '00540016': exports.RadiopharmaceuticalInformationSequence,
  '00540017': exports.ResidualSyringeCounts,
  '00540018': exports.EnergyWindowName,
  '00540020': exports.DetectorVector,
  '00540021': exports.NumberOfDetectors,
  '00540022': exports.DetectorInformationSequence,
  '00540030': exports.PhaseVector,
  '00540031': exports.NumberOfPhases,
  '00540032': exports.PhaseInformationSequence,
  '00540033': exports.NumberOfFramesInPhase,
  '00540036': exports.PhaseDelay,
  '00540038': exports.PauseBetweenFrames,
  '00540039': exports.PhaseDescription,
  '00540050': exports.RotationVector,
  '00540051': exports.NumberOfRotations,
  '00540052': exports.RotationInformationSequence,
  '00540053': exports.NumberOfFramesInRotation,
  '00540060': exports.RRIntervalVector,
  '00540061': exports.NumberOfRRIntervals,
  '00540062': exports.GatedInformationSequence,
  '00540063': exports.DataInformationSequence,
  '00540070': exports.TimeSlotVector,
  '00540071': exports.NumberOfTimeSlots,
  '00540072': exports.TimeSlotInformationSequence,
  '00540073': exports.TimeSlotTime,
  '00540080': exports.SliceVector,
  '00540081': exports.NumberOfSlices,
  '00540090': exports.AngularViewVector,
  '00540100': exports.TimeSliceVector,
  '00540101': exports.NumberOfTimeSlices,
  '00540200': exports.StartAngle,
  '00540202': exports.TypeOfDetectorMotion,
  '00540210': exports.TriggerVector,
  '00540211': exports.NumberOfTriggersInPhase,
  '00540220': exports.ViewCodeSequence,
  '00540222': exports.ViewModifierCodeSequence,
  '00540300': exports.RadionuclideCodeSequence,
  '00540302': exports.AdministrationRouteCodeSequence,
  '00540304': exports.RadiopharmaceuticalCodeSequence,
  '00540306': exports.CalibrationDataSequence,
  '00540308': exports.EnergyWindowNumber,
  '00540400': exports.ImageID,
  '00540410': exports.PatientOrientationCodeSequence,
  '00540412': exports.PatientOrientationModifierCodeSequence,
  '00540414': exports.PatientGantryRelationshipCodeSequence,
  '00540500': exports.SliceProgressionDirection,
  '00540501': exports.ScanProgressionDirection,
  '00541000': exports.SeriesType,
  '00541001': exports.Units,
  '00541002': exports.CountsSource,
  '00541004': exports.ReprojectionMethod,
  '00541006': exports.SUVType,
  '00541100': exports.RandomsCorrectionMethod,
  '00541101': exports.AttenuationCorrectionMethod,
  '00541102': exports.DecayCorrection,
  '00541103': exports.ReconstructionMethod,
  '00541104': exports.DetectorLinesOfResponseUsed,
  '00541105': exports.ScatterCorrectionMethod,
  '00541200': exports.AxialAcceptance,
  '00541201': exports.AxialMash,
  '00541202': exports.TransverseMash,
  '00541203': exports.DetectorElementSize,
  '00541210': exports.CoincidenceWindowWidth,
  '00541220': exports.SecondaryCountsType,
  '00541300': exports.FrameReferenceTime,
  '00541310': exports.PrimaryPromptsCountsAccumulated,
  '00541311': exports.SecondaryCountsAccumulated,
  '00541320': exports.SliceSensitivityFactor,
  '00541321': exports.DecayFactor,
  '00541322': exports.DoseCalibrationFactor,
  '00541323': exports.ScatterFractionFactor,
  '00541324': exports.DeadTimeFactor,
  '00541330': exports.ImageIndex,
  '00541400': exports.CountsIncluded,
  '00541401': exports.DeadTimeCorrectionFlag,
  '00603000': exports.HistogramSequence,
  '00603002': exports.HistogramNumberOfBins,
  '00603004': exports.HistogramFirstBinValue,
  '00603006': exports.HistogramLastBinValue,
  '00603008': exports.HistogramBinWidth,
  '00603010': exports.HistogramExplanation,
  '00603020': exports.HistogramData,
  '00620001': exports.SegmentationType,
  '00620002': exports.SegmentSequence,
  '00620003': exports.SegmentedPropertyCategoryCodeSequence,
  '00620004': exports.SegmentNumber,
  '00620005': exports.SegmentLabel,
  '00620006': exports.SegmentDescription,
  '00620008': exports.SegmentAlgorithmType,
  '00620009': exports.SegmentAlgorithmName,
  '0062000a': exports.SegmentIdentificationSequence,
  '0062000b': exports.ReferencedSegmentNumber,
  '0062000c': exports.RecommendedDisplayGrayscaleValue,
  '0062000d': exports.RecommendedDisplayCIELabValue,
  '0062000e': exports.MaximumFractionalValue,
  '0062000f': exports.SegmentedPropertyTypeCodeSequence,
  '00620010': exports.SegmentationFractionalType,
  '00620011': exports.SegmentedPropertyTypeModifierCodeSequence,
  '00620012': exports.UsedSegmentsSequence,
  '00640002': exports.DeformableRegistrationSequence,
  '00640003': exports.SourceFrameOfReferenceUID,
  '00640005': exports.DeformableRegistrationGridSequence,
  '00640007': exports.GridDimensions,
  '00640008': exports.GridResolution,
  '00640009': exports.VectorGridData,
  '0064000f': exports.PreDeformationMatrixRegistrationSequence,
  '00640010': exports.PostDeformationMatrixRegistrationSequence,
  '00660001': exports.NumberOfSurfaces,
  '00660002': exports.SurfaceSequence,
  '00660003': exports.SurfaceNumber,
  '00660004': exports.SurfaceComments,
  '00660009': exports.SurfaceProcessing,
  '0066000a': exports.SurfaceProcessingRatio,
  '0066000b': exports.SurfaceProcessingDescription,
  '0066000c': exports.RecommendedPresentationOpacity,
  '0066000d': exports.RecommendedPresentationType,
  '0066000e': exports.FiniteVolume,
  '00660010': exports.Manifold,
  '00660011': exports.SurfacePointsSequence,
  '00660012': exports.SurfacePointsNormalsSequence,
  '00660013': exports.SurfaceMeshPrimitivesSequence,
  '00660015': exports.NumberOfSurfacePoints,
  '00660016': exports.PointCoordinatesData,
  '00660017': exports.PointPositionAccuracy,
  '00660018': exports.MeanPointDistance,
  '00660019': exports.MaximumPointDistance,
  '0066001a': exports.PointsBoundingBoxCoordinates,
  '0066001b': exports.AxisOfRotation,
  '0066001c': exports.CenterOfRotation,
  '0066001e': exports.NumberOfVectors,
  '0066001f': exports.VectorDimensionality,
  '00660020': exports.VectorAccuracy,
  '00660021': exports.VectorCoordinateData,
  '00660023': exports.TrianglePointIndexList,
  '00660024': exports.EdgePointIndexList,
  '00660025': exports.VertexPointIndexList,
  '00660026': exports.TriangleStripSequence,
  '00660027': exports.TriangleFanSequence,
  '00660028': exports.LineSequence,
  '00660029': exports.PrimitivePointIndexList,
  '0066002a': exports.SurfaceCount,
  '0066002b': exports.ReferencedSurfaceSequence,
  '0066002c': exports.ReferencedSurfaceNumber,
  '0066002d': exports.SegmentSurfaceGenerationAlgorithmIdentificationSequence,
  '0066002e': exports.SegmentSurfaceSourceInstanceSequence,
  '0066002f': exports.AlgorithmFamilyCodeSequence,
  '00660030': exports.AlgorithmNameCodeSequence,
  '00660031': exports.AlgorithmVersion,
  '00660032': exports.AlgorithmParameters,
  '00660034': exports.FacetSequence,
  '00660035': exports.SurfaceProcessingAlgorithmIdentificationSequence,
  '00660036': exports.AlgorithmName,
  '00660037': exports.RecommendedPointRadius,
  '00660038': exports.RecommendedLineThickness,
  '00686210': exports.ImplantSize,
  '00686221': exports.ImplantTemplateVersion,
  '00686222': exports.ReplacedImplantTemplateSequence,
  '00686223': exports.ImplantType,
  '00686224': exports.DerivationImplantTemplateSequence,
  '00686225': exports.OriginalImplantTemplateSequence,
  '00686226': exports.EffectiveDateTime,
  '00686230': exports.ImplantTargetAnatomySequence,
  '00686260': exports.InformationFromManufacturerSequence,
  '00686265': exports.NotificationFromManufacturerSequence,
  '00686270': exports.InformationIssueDateTime,
  '00686280': exports.InformationSummary,
  '006862a0': exports.ImplantRegulatoryDisapprovalCodeSequence,
  '006862a5': exports.OverallTemplateSpatialTolerance,
  '006862c0': exports.HPGLDocumentSequence,
  '006862d0': exports.HPGLDocumentID,
  '006862d5': exports.HPGLDocumentLabel,
  '006862e0': exports.ViewOrientationCodeSequence,
  '006862f0': exports.ViewOrientationModifier,
  '006862f2': exports.HPGLDocumentScaling,
  '00686300': exports.HPGLDocument,
  '00686310': exports.HPGLContourPenNumber,
  '00686320': exports.HPGLPenSequence,
  '00686330': exports.HPGLPenNumber,
  '00686340': exports.HPGLPenLabel,
  '00686345': exports.HPGLPenDescription,
  '00686346': exports.RecommendedRotationPoint,
  '00686347': exports.BoundingRectangle,
  '00686350': exports.ImplantTemplate3DModelSurfaceNumber,
  '00686360': exports.SurfaceModelDescriptionSequence,
  '00686380': exports.SurfaceModelLabel,
  '00686390': exports.SurfaceModelScalingFactor,
  '006863a0': exports.MaterialsCodeSequence,
  '006863a4': exports.CoatingMaterialsCodeSequence,
  '006863a8': exports.ImplantTypeCodeSequence,
  '006863ac': exports.FixationMethodCodeSequence,
  '006863b0': exports.MatingFeatureSetsSequence,
  '006863c0': exports.MatingFeatureSetID,
  '006863d0': exports.MatingFeatureSetLabel,
  '006863e0': exports.MatingFeatureSequence,
  '006863f0': exports.MatingFeatureID,
  '00686400': exports.MatingFeatureDegreeOfFreedomSequence,
  '00686410': exports.DegreeOfFreedomID,
  '00686420': exports.DegreeOfFreedomType,
  '00686430': exports.TwoDMatingFeatureCoordinatesSequence,
  '00686440': exports.ReferencedHPGLDocumentID,
  '00686450': exports.TwoDMatingPoint,
  '00686460': exports.TwoDMatingAxes,
  '00686470': exports.TwoDDegreeOfFreedomSequence,
  '00686490': exports.ThreeDDegreeOfFreedomAxis,
  '006864a0': exports.RangeOfFreedom,
  '006864c0': exports.ThreeDMatingPoint,
  '006864d0': exports.ThreeDMatingAxes,
  '006864f0': exports.TwoDDegreeOfFreedomAxis,
  '00686500': exports.PlanningLandmarkPointSequence,
  '00686510': exports.PlanningLandmarkLineSequence,
  '00686520': exports.PlanningLandmarkPlaneSequence,
  '00686530': exports.PlanningLandmarkID,
  '00686540': exports.PlanningLandmarkDescription,
  '00686545': exports.PlanningLandmarkIdentificationCodeSequence,
  '00686550': exports.TwoDPointCoordinatesSequence,
  '00686560': exports.TwoDPointCoordinates,
  '00686590': exports.ThreeDPointCoordinates,
  '006865a0': exports.TwoDLineCoordinatesSequence,
  '006865b0': exports.TwoDLineCoordinates,
  '006865d0': exports.ThreeDLineCoordinates,
  '006865e0': exports.TwoDPlaneCoordinatesSequence,
  '006865f0': exports.TwoDPlaneIntersection,
  '00686610': exports.ThreeDPlaneOrigin,
  '00686620': exports.ThreeDPlaneNormal,
  '00700001': exports.GraphicAnnotationSequence,
  '00700002': exports.GraphicLayer,
  '00700003': exports.BoundingBoxAnnotationUnits,
  '00700004': exports.AnchorPointAnnotationUnits,
  '00700005': exports.GraphicAnnotationUnits,
  '00700006': exports.UnformattedTextValue,
  '00700008': exports.TextObjectSequence,
  '00700009': exports.GraphicObjectSequence,
  '00700010': exports.BoundingBoxTopLeftHandCorner,
  '00700011': exports.BoundingBoxBottomRightHandCorner,
  '00700012': exports.BoundingBoxTextHorizontalJustification,
  '00700014': exports.AnchorPoint,
  '00700015': exports.AnchorPointVisibility,
  '00700020': exports.GraphicDimensions,
  '00700021': exports.NumberOfGraphicPoints,
  '00700022': exports.GraphicData,
  '00700023': exports.GraphicType,
  '00700024': exports.GraphicFilled,
  '00700040': exports.ImageRotationRetired,
  '00700041': exports.ImageHorizontalFlip,
  '00700042': exports.ImageRotation,
  '00700050': exports.DisplayedAreaTopLeftHandCornerTrial,
  '00700051': exports.DisplayedAreaBottomRightHandCornerTrial,
  '00700052': exports.DisplayedAreaTopLeftHandCorner,
  '00700053': exports.DisplayedAreaBottomRightHandCorner,
  '0070005a': exports.DisplayedAreaSelectionSequence,
  '00700060': exports.GraphicLayerSequence,
  '00700062': exports.GraphicLayerOrder,
  '00700066': exports.GraphicLayerRecommendedDisplayGrayscaleValue,
  '00700067': exports.GraphicLayerRecommendedDisplayRGBValue,
  '00700068': exports.GraphicLayerDescription,
  '00700080': exports.ContentLabel,
  '00700081': exports.ContentDescription,
  '00700082': exports.PresentationCreationDate,
  '00700083': exports.PresentationCreationTime,
  '00700084': exports.ContentCreatorName,
  '00700086': exports.ContentCreatorIdentificationCodeSequence,
  '00700087': exports.AlternateContentDescriptionSequence,
  '00700100': exports.PresentationSizeMode,
  '00700101': exports.PresentationPixelSpacing,
  '00700102': exports.PresentationPixelAspectRatio,
  '00700103': exports.PresentationPixelMagnificationRatio,
  '00700207': exports.GraphicGroupLabel,
  '00700208': exports.GraphicGroupDescription,
  '00700209': exports.CompoundGraphicSequence,
  '00700226': exports.CompoundGraphicInstanceID,
  '00700227': exports.FontName,
  '00700228': exports.FontNameType,
  '00700229': exports.CSSFontName,
  '00700230': exports.RotationAngle,
  '00700231': exports.TextStyleSequence,
  '00700232': exports.LineStyleSequence,
  '00700233': exports.FillStyleSequence,
  '00700234': exports.GraphicGroupSequence,
  '00700241': exports.TextColorCIELabValue,
  '00700242': exports.HorizontalAlignment,
  '00700243': exports.VerticalAlignment,
  '00700244': exports.ShadowStyle,
  '00700245': exports.ShadowOffsetX,
  '00700246': exports.ShadowOffsetY,
  '00700247': exports.ShadowColorCIELabValue,
  '00700248': exports.Underlined,
  '00700249': exports.Bold,
  '00700250': exports.Italic,
  '00700251': exports.PatternOnColorCIELabValue,
  '00700252': exports.PatternOffColorCIELabValue,
  '00700253': exports.LineThickness,
  '00700254': exports.LineDashingStyle,
  '00700255': exports.LinePattern,
  '00700256': exports.FillPattern,
  '00700257': exports.FillMode,
  '00700258': exports.ShadowOpacity,
  '00700261': exports.GapLength,
  '00700262': exports.DiameterOfVisibility,
  '00700273': exports.RotationPoint,
  '00700274': exports.TickAlignment,
  '00700278': exports.ShowTickLabel,
  '00700279': exports.TickLabelAlignment,
  '00700282': exports.CompoundGraphicUnits,
  '00700284': exports.PatternOnOpacity,
  '00700285': exports.PatternOffOpacity,
  '00700287': exports.MajorTicksSequence,
  '00700288': exports.TickPosition,
  '00700289': exports.TickLabel,
  '00700294': exports.CompoundGraphicType,
  '00700295': exports.GraphicGroupID,
  '00700306': exports.ShapeType,
  '00700308': exports.RegistrationSequence,
  '00700309': exports.MatrixRegistrationSequence,
  '0070030a': exports.MatrixSequence,
  '0070030c': exports.FrameOfReferenceTransformationMatrixType,
  '0070030d': exports.RegistrationTypeCodeSequence,
  '0070030f': exports.FiducialDescription,
  '00700310': exports.FiducialIdentifier,
  '00700311': exports.FiducialIdentifierCodeSequence,
  '00700312': exports.ContourUncertaintyRadius,
  '00700314': exports.UsedFiducialsSequence,
  '00700318': exports.GraphicCoordinatesDataSequence,
  '0070031a': exports.FiducialUID,
  '0070031c': exports.FiducialSetSequence,
  '0070031e': exports.FiducialSequence,
  '00700401': exports.GraphicLayerRecommendedDisplayCIELabValue,
  '00700402': exports.BlendingSequence,
  '00700403': exports.RelativeOpacity,
  '00700404': exports.ReferencedSpatialRegistrationSequence,
  '00700405': exports.BlendingPosition,
  '00720002': exports.HangingProtocolName,
  '00720004': exports.HangingProtocolDescription,
  '00720006': exports.HangingProtocolLevel,
  '00720008': exports.HangingProtocolCreator,
  '0072000a': exports.HangingProtocolCreationDateTime,
  '0072000c': exports.HangingProtocolDefinitionSequence,
  '0072000e': exports.HangingProtocolUserIdentificationCodeSequence,
  '00720010': exports.HangingProtocolUserGroupName,
  '00720012': exports.SourceHangingProtocolSequence,
  '00720014': exports.NumberOfPriorsReferenced,
  '00720020': exports.ImageSetsSequence,
  '00720022': exports.ImageSetSelectorSequence,
  '00720024': exports.ImageSetSelectorUsageFlag,
  '00720026': exports.SelectorAttribute,
  '00720028': exports.SelectorValueNumber,
  '00720030': exports.TimeBasedImageSetsSequence,
  '00720032': exports.ImageSetNumber,
  '00720034': exports.ImageSetSelectorCategory,
  '00720038': exports.RelativeTime,
  '0072003a': exports.RelativeTimeUnits,
  '0072003c': exports.AbstractPriorValue,
  '0072003e': exports.AbstractPriorCodeSequence,
  '00720040': exports.ImageSetLabel,
  '00720050': exports.SelectorAttributeVR,
  '00720052': exports.SelectorSequencePointer,
  '00720054': exports.SelectorSequencePointerPrivateCreator,
  '00720056': exports.SelectorAttributePrivateCreator,
  '00720060': exports.SelectorATValue,
  '00720062': exports.SelectorCSValue,
  '00720064': exports.SelectorISValue,
  '00720066': exports.SelectorLOValue,
  '00720068': exports.SelectorLTValue,
  '0072006a': exports.SelectorPNValue,
  '0072006c': exports.SelectorSHValue,
  '0072006e': exports.SelectorSTValue,
  '00720070': exports.SelectorUTValue,
  '00720072': exports.SelectorDSValue,
  '00720074': exports.SelectorFDValue,
  '00720076': exports.SelectorFLValue,
  '00720078': exports.SelectorULValue,
  '0072007a': exports.SelectorUSValue,
  '0072007c': exports.SelectorSLValue,
  '0072007e': exports.SelectorSSValue,
  '00720080': exports.SelectorCodeSequenceValue,
  '00720100': exports.NumberOfScreens,
  '00720102': exports.NominalScreenDefinitionSequence,
  '00720104': exports.NumberOfVerticalPixels,
  '00720106': exports.NumberOfHorizontalPixels,
  '00720108': exports.DisplayEnvironmentSpatialPosition,
  '0072010a': exports.ScreenMinimumGrayscaleBitDepth,
  '0072010c': exports.ScreenMinimumColorBitDepth,
  '0072010e': exports.ApplicationMaximumRepaintTime,
  '00720200': exports.DisplaySetsSequence,
  '00720202': exports.DisplaySetNumber,
  '00720203': exports.DisplaySetLabel,
  '00720204': exports.DisplaySetPresentationGroup,
  '00720206': exports.DisplaySetPresentationGroupDescription,
  '00720208': exports.PartialDataDisplayHandling,
  '00720210': exports.SynchronizedScrollingSequence,
  '00720212': exports.DisplaySetScrollingGroup,
  '00720214': exports.NavigationIndicatorSequence,
  '00720216': exports.NavigationDisplaySet,
  '00720218': exports.ReferenceDisplaySets,
  '00720300': exports.ImageBoxesSequence,
  '00720302': exports.ImageBoxNumber,
  '00720304': exports.ImageBoxLayoutType,
  '00720306': exports.ImageBoxTileHorizontalDimension,
  '00720308': exports.ImageBoxTileVerticalDimension,
  '00720310': exports.ImageBoxScrollDirection,
  '00720312': exports.ImageBoxSmallScrollType,
  '00720314': exports.ImageBoxSmallScrollAmount,
  '00720316': exports.ImageBoxLargeScrollType,
  '00720318': exports.ImageBoxLargeScrollAmount,
  '00720320': exports.ImageBoxOverlapPriority,
  '00720330': exports.CineRelativeToRealTime,
  '00720400': exports.FilterOperationsSequence,
  '00720402': exports.FilterByCategory,
  '00720404': exports.FilterByAttributePresence,
  '00720406': exports.FilterByOperator,
  '00720420': exports.StructuredDisplayBackgroundCIELabValue,
  '00720421': exports.EmptyImageBoxCIELabValue,
  '00720422': exports.StructuredDisplayImageBoxSequence,
  '00720424': exports.StructuredDisplayTextBoxSequence,
  '00720427': exports.ReferencedFirstFrameSequence,
  '00720430': exports.ImageBoxSynchronizationSequence,
  '00720432': exports.SynchronizedImageBoxList,
  '00720434': exports.TypeOfSynchronization,
  '00720500': exports.BlendingOperationType,
  '00720510': exports.ReformattingOperationType,
  '00720512': exports.ReformattingThickness,
  '00720514': exports.ReformattingInterval,
  '00720516': exports.ReformattingOperationInitialViewDirection,
  '00720520': exports.ThreeDRenderingType,
  '00720600': exports.SortingOperationsSequence,
  '00720602': exports.SortByCategory,
  '00720604': exports.SortingDirection,
  '00720700': exports.DisplaySetPatientOrientation,
  '00720702': exports.VOIType,
  '00720704': exports.PseudoColorType,
  '00720705': exports.PseudoColorPaletteInstanceReferenceSequence,
  '00720706': exports.ShowGrayscaleInverted,
  '00720710': exports.ShowImageTrueSizeFlag,
  '00720712': exports.ShowGraphicAnnotationFlag,
  '00720714': exports.ShowPatientDemographicsFlag,
  '00720716': exports.ShowAcquisitionTechniquesFlag,
  '00720717': exports.DisplaySetHorizontalJustification,
  '00720718': exports.DisplaySetVerticalJustification,
  '00740120': exports.ContinuationStartMeterset,
  '00740121': exports.ContinuationEndMeterset,
  '00741000': exports.ProcedureStepState,
  '00741002': exports.ProcedureStepProgressInformationSequence,
  '00741004': exports.ProcedureStepProgress,
  '00741006': exports.ProcedureStepProgressDescription,
  '00741008': exports.ProcedureStepCommunicationsURISequence,
  '0074100a': exports.ContactURI,
  '0074100c': exports.ContactDisplayName,
  '0074100e': exports.ProcedureStepDiscontinuationReasonCodeSequence,
  '00741020': exports.BeamTaskSequence,
  '00741022': exports.BeamTaskType,
  '00741024': exports.BeamOrderIndexTrial,
  '00741025': exports.AutosequenceFlag,
  '00741026': exports.TableTopVerticalAdjustedPosition,
  '00741027': exports.TableTopLongitudinalAdjustedPosition,
  '00741028': exports.TableTopLateralAdjustedPosition,
  '0074102a': exports.PatientSupportAdjustedAngle,
  '0074102b': exports.TableTopEccentricAdjustedAngle,
  '0074102c': exports.TableTopPitchAdjustedAngle,
  '0074102d': exports.TableTopRollAdjustedAngle,
  '00741030': exports.DeliveryVerificationImageSequence,
  '00741032': exports.VerificationImageTiming,
  '00741034': exports.DoubleExposureFlag,
  '00741036': exports.DoubleExposureOrdering,
  '00741038': exports.DoubleExposureMetersetTrial,
  '0074103a': exports.DoubleExposureFieldDeltaTrial,
  '00741040': exports.RelatedReferenceRTImageSequence,
  '00741042': exports.GeneralMachineVerificationSequence,
  '00741044': exports.ConventionalMachineVerificationSequence,
  '00741046': exports.IonMachineVerificationSequence,
  '00741048': exports.FailedAttributesSequence,
  '0074104a': exports.OverriddenAttributesSequence,
  '0074104c': exports.ConventionalControlPointVerificationSequence,
  '0074104e': exports.IonControlPointVerificationSequence,
  '00741050': exports.AttributeOccurrenceSequence,
  '00741052': exports.AttributeOccurrencePointer,
  '00741054': exports.AttributeItemSelector,
  '00741056': exports.AttributeOccurrencePrivateCreator,
  '00741057': exports.SelectorSequencePointerItems,
  '00741200': exports.ScheduledProcedureStepPriority,
  '00741202': exports.WorklistLabel,
  '00741204': exports.ProcedureStepLabel,
  '00741210': exports.ScheduledProcessingParametersSequence,
  '00741212': exports.PerformedProcessingParametersSequence,
  '00741216': exports.UnifiedProcedureStepPerformedProcedureSequence,
  '00741220': exports.RelatedProcedureStepSequence,
  '00741222': exports.ProcedureStepRelationshipType,
  '00741224': exports.ReplacedProcedureStepSequence,
  '00741230': exports.DeletionLock,
  '00741234': exports.ReceivingAE,
  '00741236': exports.RequestingAE,
  '00741238': exports.ReasonForCancellation,
  '00741242': exports.SCPStatus,
  '00741244': exports.SubscriptionListStatus,
  '00741246': exports.UnifiedProcedureStepListStatus,
  '00741324': exports.BeamOrderIndex,
  '00741338': exports.DoubleExposureMeterset,
  '0074133a': exports.DoubleExposureFieldDelta,
  '00760001': exports.ImplantAssemblyTemplateName,
  '00760003': exports.ImplantAssemblyTemplateIssuer,
  '00760006': exports.ImplantAssemblyTemplateVersion,
  '00760008': exports.ReplacedImplantAssemblyTemplateSequence,
  '0076000a': exports.ImplantAssemblyTemplateType,
  '0076000c': exports.OriginalImplantAssemblyTemplateSequence,
  '0076000e': exports.DerivationImplantAssemblyTemplateSequence,
  '00760010': exports.ImplantAssemblyTemplateTargetAnatomySequence,
  '00760020': exports.ProcedureTypeCodeSequence,
  '00760030': exports.SurgicalTechnique,
  '00760032': exports.ComponentTypesSequence,
  '00760034': exports.ComponentTypeCodeSequence,
  '00760036': exports.ExclusiveComponentType,
  '00760038': exports.MandatoryComponentType,
  '00760040': exports.ComponentSequence,
  '00760055': exports.ComponentID,
  '00760060': exports.ComponentAssemblySequence,
  '00760070': exports.Component1ReferencedID,
  '00760080': exports.Component1ReferencedMatingFeatureSetID,
  '00760090': exports.Component1ReferencedMatingFeatureID,
  '007600a0': exports.Component2ReferencedID,
  '007600b0': exports.Component2ReferencedMatingFeatureSetID,
  '007600c0': exports.Component2ReferencedMatingFeatureID,
  '00780001': exports.ImplantTemplateGroupName,
  '00780010': exports.ImplantTemplateGroupDescription,
  '00780020': exports.ImplantTemplateGroupIssuer,
  '00780024': exports.ImplantTemplateGroupVersion,
  '00780026': exports.ReplacedImplantTemplateGroupSequence,
  '00780028': exports.ImplantTemplateGroupTargetAnatomySequence,
  '0078002a': exports.ImplantTemplateGroupMembersSequence,
  '0078002e': exports.ImplantTemplateGroupMemberID,
  '00780050': exports.ThreeDImplantTemplateGroupMemberMatchingPoint,
  '00780060': exports.ThreeDImplantTemplateGroupMemberMatchingAxes,
  '00780070': exports.ImplantTemplateGroupMemberMatching2DCoordinatesSequence,
  '00780090': exports.TwoDImplantTemplateGroupMemberMatchingPoint,
  '007800a0': exports.TwoDImplantTemplateGroupMemberMatchingAxes,
  '007800b0': exports.ImplantTemplateGroupVariationDimensionSequence,
  '007800b2': exports.ImplantTemplateGroupVariationDimensionName,
  '007800b4': exports.ImplantTemplateGroupVariationDimensionRankSequence,
  '007800b6': exports.ReferencedImplantTemplateGroupMemberID,
  '007800b8': exports.ImplantTemplateGroupVariationDimensionRank,
  '00800001': exports.SurfaceScanAcquisitionTypeCodeSequence,
  '00800002': exports.SurfaceScanModeCodeSequence,
  '00800003': exports.RegistrationMethodCodeSequence,
  '00800004': exports.ShotDurationTime,
  '00800005': exports.ShotOffsetTime,
  '00800006': exports.SurfacePointPresentationValueData,
  '00800007': exports.SurfacePointColorCIELabValueData,
  '00800008': exports.UVMappingSequence,
  '00800009': exports.TextureLabel,
  '00800010': exports.UValueData,
  '00800011': exports.VValueData,
  '00800012': exports.ReferencedTextureSequence,
  '00800013': exports.ReferencedSurfaceDataSequence,
  '00880130': exports.StorageMediaFileSetID,
  '00880140': exports.StorageMediaFileSetUID,
  '00880200': exports.IconImageSequence,
  '00880904': exports.TopicTitle,
  '00880906': exports.TopicSubject,
  '00880910': exports.TopicAuthor,
  '00880912': exports.TopicKeywords,
  '01000410': exports.SOPInstanceStatus,
  '01000420': exports.SOPAuthorizationDateTime,
  '01000424': exports.SOPAuthorizationComment,
  '01000426': exports.AuthorizationEquipmentCertificationNumber,
  '04000005': exports.MACIDNumber,
  '04000010': exports.MACCalculationTransferSyntaxUID,
  '04000015': exports.MACAlgorithm,
  '04000020': exports.DataElementsSigned,
  '04000100': exports.DigitalSignatureUID,
  '04000105': exports.DigitalSignatureDateTime,
  '04000110': exports.CertificateType,
  '04000115': exports.CertificateOfSigner,
  '04000120': exports.Signature,
  '04000305': exports.CertifiedTimestampType,
  '04000310': exports.CertifiedTimestamp,
  '04000401': exports.DigitalSignaturePurposeCodeSequence,
  '04000402': exports.ReferencedDigitalSignatureSequence,
  '04000403': exports.ReferencedSOPInstanceMACSequence,
  '04000404': exports.MAC,
  '04000500': exports.EncryptedAttributesSequence,
  '04000510': exports.EncryptedContentTransferSyntaxUID,
  '04000520': exports.EncryptedContent,
  '04000550': exports.ModifiedAttributesSequence,
  '04000561': exports.OriginalAttributesSequence,
  '04000562': exports.AttributeModificationDateTime,
  '04000563': exports.ModifyingSystem,
  '04000564': exports.SourceOfPreviousValues,
  '04000565': exports.ReasonForTheAttributeModification,
  '10000000': exports.EscapeTriplet,
  '10000001': exports.RunLengthTriplet,
  '10000002': exports.HuffmanTableSize,
  '10000003': exports.HuffmanTableTriplet,
  '10000004': exports.ShiftTableSize,
  '10000005': exports.ShiftTableTriplet,
  '10100000': exports.ZonalMap,
  '20000010': exports.NumberOfCopies,
  '2000001e': exports.PrinterConfigurationSequence,
  '20000020': exports.PrintPriority,
  '20000030': exports.MediumType,
  '20000040': exports.FilmDestination,
  '20000050': exports.FilmSessionLabel,
  '20000060': exports.MemoryAllocation,
  '20000061': exports.MaximumMemoryAllocation,
  '20000062': exports.ColorImagePrintingFlag,
  '20000063': exports.CollationFlag,
  '20000065': exports.AnnotationFlag,
  '20000067': exports.ImageOverlayFlag,
  '20000069': exports.PresentationLUTFlag,
  '2000006a': exports.ImageBoxPresentationLUTFlag,
  '200000a0': exports.MemoryBitDepth,
  '200000a1': exports.PrintingBitDepth,
  '200000a2': exports.MediaInstalledSequence,
  '200000a4': exports.OtherMediaAvailableSequence,
  '200000a8': exports.SupportedImageDisplayFormatsSequence,
  '20000500': exports.ReferencedFilmBoxSequence,
  '20000510': exports.ReferencedStoredPrintSequence,
  '20100010': exports.ImageDisplayFormat,
  '20100030': exports.AnnotationDisplayFormatID,
  '20100040': exports.FilmOrientation,
  '20100050': exports.FilmSizeID,
  '20100052': exports.PrinterResolutionID,
  '20100054': exports.DefaultPrinterResolutionID,
  '20100060': exports.MagnificationType,
  '20100080': exports.SmoothingType,
  '201000a6': exports.DefaultMagnificationType,
  '201000a7': exports.OtherMagnificationTypesAvailable,
  '201000a8': exports.DefaultSmoothingType,
  '201000a9': exports.OtherSmoothingTypesAvailable,
  '20100100': exports.BorderDensity,
  '20100110': exports.EmptyImageDensity,
  '20100120': exports.MinDensity,
  '20100130': exports.MaxDensity,
  '20100140': exports.Trim,
  '20100150': exports.ConfigurationInformation,
  '20100152': exports.ConfigurationInformationDescription,
  '20100154': exports.MaximumCollatedFilms,
  '2010015e': exports.Illumination,
  '20100160': exports.ReflectedAmbientLight,
  '20100376': exports.PrinterPixelSpacing,
  '20100500': exports.ReferencedFilmSessionSequence,
  '20100510': exports.ReferencedImageBoxSequence,
  '20100520': exports.ReferencedBasicAnnotationBoxSequence,
  '20200010': exports.ImageBoxPosition,
  '20200020': exports.Polarity,
  '20200030': exports.RequestedImageSize,
  '20200040': exports.RequestedDecimateCropBehavior,
  '20200050': exports.RequestedResolutionID,
  '202000a0': exports.RequestedImageSizeFlag,
  '202000a2': exports.DecimateCropResult,
  '20200110': exports.BasicGrayscaleImageSequence,
  '20200111': exports.BasicColorImageSequence,
  '20200130': exports.ReferencedImageOverlayBoxSequence,
  '20200140': exports.ReferencedVOILUTBoxSequence,
  '20300010': exports.AnnotationPosition,
  '20300020': exports.TextString,
  '20400010': exports.ReferencedOverlayPlaneSequence,
  '20400011': exports.ReferencedOverlayPlaneGroups,
  '20400020': exports.OverlayPixelDataSequence,
  '20400060': exports.OverlayMagnificationType,
  '20400070': exports.OverlaySmoothingType,
  '20400072': exports.OverlayOrImageMagnification,
  '20400074': exports.MagnifyToNumberOfColumns,
  '20400080': exports.OverlayForegroundDensity,
  '20400082': exports.OverlayBackgroundDensity,
  '20400090': exports.OverlayMode,
  '20400100': exports.ThresholdDensity,
  '20400500': exports.ReferencedImageBoxSequenceRetired,
  '20500010': exports.PresentationLUTSequence,
  '20500020': exports.PresentationLUTShape,
  '20500500': exports.ReferencedPresentationLUTSequence,
  '21000010': exports.PrintJobID,
  '21000020': exports.ExecutionStatus,
  '21000030': exports.ExecutionStatusInfo,
  '21000040': exports.CreationDate,
  '21000050': exports.CreationTime,
  '21000070': exports.Originator,
  '21000140': exports.DestinationAE,
  '21000160': exports.OwnerID,
  '21000170': exports.NumberOfFilms,
  '21000500': exports.ReferencedPrintJobSequencePullStoredPrint,
  '21100010': exports.PrinterStatus,
  '21100020': exports.PrinterStatusInfo,
  '21100030': exports.PrinterName,
  '21100099': exports.PrintQueueID,
  '21200010': exports.QueueStatus,
  '21200050': exports.PrintJobDescriptionSequence,
  '21200070': exports.ReferencedPrintJobSequence,
  '21300010': exports.PrintManagementCapabilitiesSequence,
  '21300015': exports.PrinterCharacteristicsSequence,
  '21300030': exports.FilmBoxContentSequence,
  '21300040': exports.ImageBoxContentSequence,
  '21300050': exports.AnnotationContentSequence,
  '21300060': exports.ImageOverlayBoxContentSequence,
  '21300080': exports.PresentationLUTContentSequence,
  '213000a0': exports.ProposedStudySequence,
  '213000c0': exports.OriginalImageSequence,
  '22000001': exports.LabelUsingInformationExtractedFromInstances,
  '22000002': exports.LabelText,
  '22000003': exports.LabelStyleSelection,
  '22000004': exports.MediaDisposition,
  '22000005': exports.BarcodeValue,
  '22000006': exports.BarcodeSymbology,
  '22000007': exports.AllowMediaSplitting,
  '22000008': exports.IncludeNonDICOMObjects,
  '22000009': exports.IncludeDisplayApplication,
  '2200000a': exports.PreserveCompositeInstancesAfterMediaCreation,
  '2200000b': exports.TotalNumberOfPiecesOfMediaCreated,
  '2200000c': exports.RequestedMediaApplicationProfile,
  '2200000d': exports.ReferencedStorageMediaSequence,
  '2200000e': exports.FailureAttributes,
  '2200000f': exports.AllowLossyCompression,
  '22000020': exports.RequestPriority,
  '30020002': exports.RTImageLabel,
  '30020003': exports.RTImageName,
  '30020004': exports.RTImageDescription,
  '3002000a': exports.ReportedValuesOrigin,
  '3002000c': exports.RTImagePlane,
  '3002000d': exports.XRayImageReceptorTranslation,
  '3002000e': exports.XRayImageReceptorAngle,
  '30020010': exports.RTImageOrientation,
  '30020011': exports.ImagePlanePixelSpacing,
  '30020012': exports.RTImagePosition,
  '30020020': exports.RadiationMachineName,
  '30020022': exports.RadiationMachineSAD,
  '30020024': exports.RadiationMachineSSD,
  '30020026': exports.RTImageSID,
  '30020028': exports.SourceToReferenceObjectDistance,
  '30020029': exports.FractionNumber,
  '30020030': exports.ExposureSequence,
  '30020032': exports.MetersetExposure,
  '30020034': exports.DiaphragmPosition,
  '30020040': exports.FluenceMapSequence,
  '30020041': exports.FluenceDataSource,
  '30020042': exports.FluenceDataScale,
  '30020050': exports.PrimaryFluenceModeSequence,
  '30020051': exports.FluenceMode,
  '30020052': exports.FluenceModeID,
  '30040001': exports.DVHType,
  '30040002': exports.DoseUnits,
  '30040004': exports.DoseType,
  '30040005': exports.SpatialTransformOfDose,
  '30040006': exports.DoseComment,
  '30040008': exports.NormalizationPoint,
  '3004000a': exports.DoseSummationType,
  '3004000c': exports.GridFrameOffsetVector,
  '3004000e': exports.DoseGridScaling,
  '30040010': exports.RTDoseROISequence,
  '30040012': exports.DoseValue,
  '30040014': exports.TissueHeterogeneityCorrection,
  '30040040': exports.DVHNormalizationPoint,
  '30040042': exports.DVHNormalizationDoseValue,
  '30040050': exports.DVHSequence,
  '30040052': exports.DVHDoseScaling,
  '30040054': exports.DVHVolumeUnits,
  '30040056': exports.DVHNumberOfBins,
  '30040058': exports.DVHData,
  '30040060': exports.DVHReferencedROISequence,
  '30040062': exports.DVHROIContributionType,
  '30040070': exports.DVHMinimumDose,
  '30040072': exports.DVHMaximumDose,
  '30040074': exports.DVHMeanDose,
  '30060002': exports.StructureSetLabel,
  '30060004': exports.StructureSetName,
  '30060006': exports.StructureSetDescription,
  '30060008': exports.StructureSetDate,
  '30060009': exports.StructureSetTime,
  '30060010': exports.ReferencedFrameOfReferenceSequence,
  '30060012': exports.RTReferencedStudySequence,
  '30060014': exports.RTReferencedSeriesSequence,
  '30060016': exports.ContourImageSequence,
  '30060018': exports.PredecessorStructureSetSequence,
  '30060020': exports.StructureSetROISequence,
  '30060022': exports.ROINumber,
  '30060024': exports.ReferencedFrameOfReferenceUID,
  '30060026': exports.ROIName,
  '30060028': exports.ROIDescription,
  '3006002a': exports.ROIDisplayColor,
  '3006002c': exports.ROIVolume,
  '30060030': exports.RTRelatedROISequence,
  '30060033': exports.RTROIRelationship,
  '30060036': exports.ROIGenerationAlgorithm,
  '30060038': exports.ROIGenerationDescription,
  '30060039': exports.ROIContourSequence,
  '30060040': exports.ContourSequence,
  '30060042': exports.ContourGeometricType,
  '30060044': exports.ContourSlabThickness,
  '30060045': exports.ContourOffsetVector,
  '30060046': exports.NumberOfContourPoints,
  '30060048': exports.ContourNumber,
  '30060049': exports.AttachedContours,
  '30060050': exports.ContourData,
  '30060080': exports.RTROIObservationsSequence,
  '30060082': exports.ObservationNumber,
  '30060084': exports.ReferencedROINumber,
  '30060085': exports.ROIObservationLabel,
  '30060086': exports.RTROIIdentificationCodeSequence,
  '30060088': exports.ROIObservationDescription,
  '300600a0': exports.RelatedRTROIObservationsSequence,
  '300600a4': exports.RTROIInterpretedType,
  '300600a6': exports.ROIInterpreter,
  '300600b0': exports.ROIPhysicalPropertiesSequence,
  '300600b2': exports.ROIPhysicalProperty,
  '300600b4': exports.ROIPhysicalPropertyValue,
  '300600b6': exports.ROIElementalCompositionSequence,
  '300600b7': exports.ROIElementalCompositionAtomicNumber,
  '300600b8': exports.ROIElementalCompositionAtomicMassFraction,
  '300600b9': exports.AdditionalRTROIIdentificationCodeSequence,
  '300600c0': exports.FrameOfReferenceRelationshipSequence,
  '300600c2': exports.RelatedFrameOfReferenceUID,
  '300600c4': exports.FrameOfReferenceTransformationType,
  '300600c6': exports.FrameOfReferenceTransformationMatrix,
  '300600c8': exports.FrameOfReferenceTransformationComment,
  '30080010': exports.MeasuredDoseReferenceSequence,
  '30080012': exports.MeasuredDoseDescription,
  '30080014': exports.MeasuredDoseType,
  '30080016': exports.MeasuredDoseValue,
  '30080020': exports.TreatmentSessionBeamSequence,
  '30080021': exports.TreatmentSessionIonBeamSequence,
  '30080022': exports.CurrentFractionNumber,
  '30080024': exports.TreatmentControlPointDate,
  '30080025': exports.TreatmentControlPointTime,
  '3008002a': exports.TreatmentTerminationStatus,
  '3008002b': exports.TreatmentTerminationCode,
  '3008002c': exports.TreatmentVerificationStatus,
  '30080030': exports.ReferencedTreatmentRecordSequence,
  '30080032': exports.SpecifiedPrimaryMeterset,
  '30080033': exports.SpecifiedSecondaryMeterset,
  '30080036': exports.DeliveredPrimaryMeterset,
  '30080037': exports.DeliveredSecondaryMeterset,
  '3008003a': exports.SpecifiedTreatmentTime,
  '3008003b': exports.DeliveredTreatmentTime,
  '30080040': exports.ControlPointDeliverySequence,
  '30080041': exports.IonControlPointDeliverySequence,
  '30080042': exports.SpecifiedMeterset,
  '30080044': exports.DeliveredMeterset,
  '30080045': exports.MetersetRateSet,
  '30080046': exports.MetersetRateDelivered,
  '30080047': exports.ScanSpotMetersetsDelivered,
  '30080048': exports.DoseRateDelivered,
  '30080050': exports.TreatmentSummaryCalculatedDoseReferenceSequence,
  '30080052': exports.CumulativeDoseToDoseReference,
  '30080054': exports.FirstTreatmentDate,
  '30080056': exports.MostRecentTreatmentDate,
  '3008005a': exports.NumberOfFractionsDelivered,
  '30080060': exports.OverrideSequence,
  '30080061': exports.ParameterSequencePointer,
  '30080062': exports.OverrideParameterPointer,
  '30080063': exports.ParameterItemIndex,
  '30080064': exports.MeasuredDoseReferenceNumber,
  '30080065': exports.ParameterPointer,
  '30080066': exports.OverrideReason,
  '30080068': exports.CorrectedParameterSequence,
  '3008006a': exports.CorrectionValue,
  '30080070': exports.CalculatedDoseReferenceSequence,
  '30080072': exports.CalculatedDoseReferenceNumber,
  '30080074': exports.CalculatedDoseReferenceDescription,
  '30080076': exports.CalculatedDoseReferenceDoseValue,
  '30080078': exports.StartMeterset,
  '3008007a': exports.EndMeterset,
  '30080080': exports.ReferencedMeasuredDoseReferenceSequence,
  '30080082': exports.ReferencedMeasuredDoseReferenceNumber,
  '30080090': exports.ReferencedCalculatedDoseReferenceSequence,
  '30080092': exports.ReferencedCalculatedDoseReferenceNumber,
  '300800a0': exports.BeamLimitingDeviceLeafPairsSequence,
  '300800b0': exports.RecordedWedgeSequence,
  '300800c0': exports.RecordedCompensatorSequence,
  '300800d0': exports.RecordedBlockSequence,
  '300800e0': exports.TreatmentSummaryMeasuredDoseReferenceSequence,
  '300800f0': exports.RecordedSnoutSequence,
  '300800f2': exports.RecordedRangeShifterSequence,
  '300800f4': exports.RecordedLateralSpreadingDeviceSequence,
  '300800f6': exports.RecordedRangeModulatorSequence,
  '30080100': exports.RecordedSourceSequence,
  '30080105': exports.SourceSerialNumber,
  '30080110': exports.TreatmentSessionApplicationSetupSequence,
  '30080116': exports.ApplicationSetupCheck,
  '30080120': exports.RecordedBrachyAccessoryDeviceSequence,
  '30080122': exports.ReferencedBrachyAccessoryDeviceNumber,
  '30080130': exports.RecordedChannelSequence,
  '30080132': exports.SpecifiedChannelTotalTime,
  '30080134': exports.DeliveredChannelTotalTime,
  '30080136': exports.SpecifiedNumberOfPulses,
  '30080138': exports.DeliveredNumberOfPulses,
  '3008013a': exports.SpecifiedPulseRepetitionInterval,
  '3008013c': exports.DeliveredPulseRepetitionInterval,
  '30080140': exports.RecordedSourceApplicatorSequence,
  '30080142': exports.ReferencedSourceApplicatorNumber,
  '30080150': exports.RecordedChannelShieldSequence,
  '30080152': exports.ReferencedChannelShieldNumber,
  '30080160': exports.BrachyControlPointDeliveredSequence,
  '30080162': exports.SafePositionExitDate,
  '30080164': exports.SafePositionExitTime,
  '30080166': exports.SafePositionReturnDate,
  '30080168': exports.SafePositionReturnTime,
  '30080171': exports.PulseSpecificBrachyControlPointDeliveredSequence,
  '30080172': exports.PulseNumber,
  '30080173': exports.BrachyPulseControlPointDeliveredSequence,
  '30080200': exports.CurrentTreatmentStatus,
  '30080202': exports.TreatmentStatusComment,
  '30080220': exports.FractionGroupSummarySequence,
  '30080223': exports.ReferencedFractionNumber,
  '30080224': exports.FractionGroupType,
  '30080230': exports.BeamStopperPosition,
  '30080240': exports.FractionStatusSummarySequence,
  '30080250': exports.TreatmentDate,
  '30080251': exports.TreatmentTime,
  '300a0002': exports.RTPlanLabel,
  '300a0003': exports.RTPlanName,
  '300a0004': exports.RTPlanDescription,
  '300a0006': exports.RTPlanDate,
  '300a0007': exports.RTPlanTime,
  '300a0009': exports.TreatmentProtocols,
  '300a000a': exports.PlanIntent,
  '300a000b': exports.TreatmentSites,
  '300a000c': exports.RTPlanGeometry,
  '300a000e': exports.PrescriptionDescription,
  '300a0010': exports.DoseReferenceSequence,
  '300a0012': exports.DoseReferenceNumber,
  '300a0013': exports.DoseReferenceUID,
  '300a0014': exports.DoseReferenceStructureType,
  '300a0015': exports.NominalBeamEnergyUnit,
  '300a0016': exports.DoseReferenceDescription,
  '300a0018': exports.DoseReferencePointCoordinates,
  '300a001a': exports.NominalPriorDose,
  '300a0020': exports.DoseReferenceType,
  '300a0021': exports.ConstraintWeight,
  '300a0022': exports.DeliveryWarningDose,
  '300a0023': exports.DeliveryMaximumDose,
  '300a0025': exports.TargetMinimumDose,
  '300a0026': exports.TargetPrescriptionDose,
  '300a0027': exports.TargetMaximumDose,
  '300a0028': exports.TargetUnderdoseVolumeFraction,
  '300a002a': exports.OrganAtRiskFullVolumeDose,
  '300a002b': exports.OrganAtRiskLimitDose,
  '300a002c': exports.OrganAtRiskMaximumDose,
  '300a002d': exports.OrganAtRiskOverdoseVolumeFraction,
  '300a0040': exports.ToleranceTableSequence,
  '300a0042': exports.ToleranceTableNumber,
  '300a0043': exports.ToleranceTableLabel,
  '300a0044': exports.GantryAngleTolerance,
  '300a0046': exports.BeamLimitingDeviceAngleTolerance,
  '300a0048': exports.BeamLimitingDeviceToleranceSequence,
  '300a004a': exports.BeamLimitingDevicePositionTolerance,
  '300a004b': exports.SnoutPositionTolerance,
  '300a004c': exports.PatientSupportAngleTolerance,
  '300a004e': exports.TableTopEccentricAngleTolerance,
  '300a004f': exports.TableTopPitchAngleTolerance,
  '300a0050': exports.TableTopRollAngleTolerance,
  '300a0051': exports.TableTopVerticalPositionTolerance,
  '300a0052': exports.TableTopLongitudinalPositionTolerance,
  '300a0053': exports.TableTopLateralPositionTolerance,
  '300a0055': exports.RTPlanRelationship,
  '300a0070': exports.FractionGroupSequence,
  '300a0071': exports.FractionGroupNumber,
  '300a0072': exports.FractionGroupDescription,
  '300a0078': exports.NumberOfFractionsPlanned,
  '300a0079': exports.NumberOfFractionPatternDigitsPerDay,
  '300a007a': exports.RepeatFractionCycleLength,
  '300a007b': exports.FractionPattern,
  '300a0080': exports.NumberOfBeams,
  '300a0082': exports.BeamDoseSpecificationPoint,
  '300a0084': exports.BeamDose,
  '300a0086': exports.BeamMeterset,
  '300a0088': exports.BeamDosePointDepth,
  '300a0089': exports.BeamDosePointEquivalentDepth,
  '300a008a': exports.BeamDosePointSSD,
  '300a008b': exports.BeamDoseMeaning,
  '300a008c': exports.BeamDoseVerificationControlPointSequence,
  '300a008d': exports.AverageBeamDosePointDepth,
  '300a008e': exports.AverageBeamDosePointEquivalentDepth,
  '300a008f': exports.AverageBeamDosePointSSD,
  '300a00a0': exports.NumberOfBrachyApplicationSetups,
  '300a00a2': exports.BrachyApplicationSetupDoseSpecificationPoint,
  '300a00a4': exports.BrachyApplicationSetupDose,
  '300a00b0': exports.BeamSequence,
  '300a00b2': exports.TreatmentMachineName,
  '300a00b3': exports.PrimaryDosimeterUnit,
  '300a00b4': exports.SourceAxisDistance,
  '300a00b6': exports.BeamLimitingDeviceSequence,
  '300a00b8': exports.RTBeamLimitingDeviceType,
  '300a00ba': exports.SourceToBeamLimitingDeviceDistance,
  '300a00bb': exports.IsocenterToBeamLimitingDeviceDistance,
  '300a00bc': exports.NumberOfLeafJawPairs,
  '300a00be': exports.LeafPositionBoundaries,
  '300a00c0': exports.BeamNumber,
  '300a00c2': exports.BeamName,
  '300a00c3': exports.BeamDescription,
  '300a00c4': exports.BeamType,
  '300a00c5': exports.BeamDeliveryDurationLimit,
  '300a00c6': exports.RadiationType,
  '300a00c7': exports.HighDoseTechniqueType,
  '300a00c8': exports.ReferenceImageNumber,
  '300a00ca': exports.PlannedVerificationImageSequence,
  '300a00cc': exports.ImagingDeviceSpecificAcquisitionParameters,
  '300a00ce': exports.TreatmentDeliveryType,
  '300a00d0': exports.NumberOfWedges,
  '300a00d1': exports.WedgeSequence,
  '300a00d2': exports.WedgeNumber,
  '300a00d3': exports.WedgeType,
  '300a00d4': exports.WedgeID,
  '300a00d5': exports.WedgeAngle,
  '300a00d6': exports.WedgeFactor,
  '300a00d7': exports.TotalWedgeTrayWaterEquivalentThickness,
  '300a00d8': exports.WedgeOrientation,
  '300a00d9': exports.IsocenterToWedgeTrayDistance,
  '300a00da': exports.SourceToWedgeTrayDistance,
  '300a00db': exports.WedgeThinEdgePosition,
  '300a00dc': exports.BolusID,
  '300a00dd': exports.BolusDescription,
  '300a00e0': exports.NumberOfCompensators,
  '300a00e1': exports.MaterialID,
  '300a00e2': exports.TotalCompensatorTrayFactor,
  '300a00e3': exports.CompensatorSequence,
  '300a00e4': exports.CompensatorNumber,
  '300a00e5': exports.CompensatorID,
  '300a00e6': exports.SourceToCompensatorTrayDistance,
  '300a00e7': exports.CompensatorRows,
  '300a00e8': exports.CompensatorColumns,
  '300a00e9': exports.CompensatorPixelSpacing,
  '300a00ea': exports.CompensatorPosition,
  '300a00eb': exports.CompensatorTransmissionData,
  '300a00ec': exports.CompensatorThicknessData,
  '300a00ed': exports.NumberOfBoli,
  '300a00ee': exports.CompensatorType,
  '300a00ef': exports.CompensatorTrayID,
  '300a00f0': exports.NumberOfBlocks,
  '300a00f2': exports.TotalBlockTrayFactor,
  '300a00f3': exports.TotalBlockTrayWaterEquivalentThickness,
  '300a00f4': exports.BlockSequence,
  '300a00f5': exports.BlockTrayID,
  '300a00f6': exports.SourceToBlockTrayDistance,
  '300a00f7': exports.IsocenterToBlockTrayDistance,
  '300a00f8': exports.BlockType,
  '300a00f9': exports.AccessoryCode,
  '300a00fa': exports.BlockDivergence,
  '300a00fb': exports.BlockMountingPosition,
  '300a00fc': exports.BlockNumber,
  '300a00fe': exports.BlockName,
  '300a0100': exports.BlockThickness,
  '300a0102': exports.BlockTransmission,
  '300a0104': exports.BlockNumberOfPoints,
  '300a0106': exports.BlockData,
  '300a0107': exports.ApplicatorSequence,
  '300a0108': exports.ApplicatorID,
  '300a0109': exports.ApplicatorType,
  '300a010a': exports.ApplicatorDescription,
  '300a010c': exports.CumulativeDoseReferenceCoefficient,
  '300a010e': exports.FinalCumulativeMetersetWeight,
  '300a0110': exports.NumberOfControlPoints,
  '300a0111': exports.ControlPointSequence,
  '300a0112': exports.ControlPointIndex,
  '300a0114': exports.NominalBeamEnergy,
  '300a0115': exports.DoseRateSet,
  '300a0116': exports.WedgePositionSequence,
  '300a0118': exports.WedgePosition,
  '300a011a': exports.BeamLimitingDevicePositionSequence,
  '300a011c': exports.LeafJawPositions,
  '300a011e': exports.GantryAngle,
  '300a011f': exports.GantryRotationDirection,
  '300a0120': exports.BeamLimitingDeviceAngle,
  '300a0121': exports.BeamLimitingDeviceRotationDirection,
  '300a0122': exports.PatientSupportAngle,
  '300a0123': exports.PatientSupportRotationDirection,
  '300a0124': exports.TableTopEccentricAxisDistance,
  '300a0125': exports.TableTopEccentricAngle,
  '300a0126': exports.TableTopEccentricRotationDirection,
  '300a0128': exports.TableTopVerticalPosition,
  '300a0129': exports.TableTopLongitudinalPosition,
  '300a012a': exports.TableTopLateralPosition,
  '300a012c': exports.IsocenterPosition,
  '300a012e': exports.SurfaceEntryPoint,
  '300a0130': exports.SourceToSurfaceDistance,
  '300a0134': exports.CumulativeMetersetWeight,
  '300a0140': exports.TableTopPitchAngle,
  '300a0142': exports.TableTopPitchRotationDirection,
  '300a0144': exports.TableTopRollAngle,
  '300a0146': exports.TableTopRollRotationDirection,
  '300a0148': exports.HeadFixationAngle,
  '300a014a': exports.GantryPitchAngle,
  '300a014c': exports.GantryPitchRotationDirection,
  '300a014e': exports.GantryPitchAngleTolerance,
  '300a0180': exports.PatientSetupSequence,
  '300a0182': exports.PatientSetupNumber,
  '300a0183': exports.PatientSetupLabel,
  '300a0184': exports.PatientAdditionalPosition,
  '300a0190': exports.FixationDeviceSequence,
  '300a0192': exports.FixationDeviceType,
  '300a0194': exports.FixationDeviceLabel,
  '300a0196': exports.FixationDeviceDescription,
  '300a0198': exports.FixationDevicePosition,
  '300a0199': exports.FixationDevicePitchAngle,
  '300a019a': exports.FixationDeviceRollAngle,
  '300a01a0': exports.ShieldingDeviceSequence,
  '300a01a2': exports.ShieldingDeviceType,
  '300a01a4': exports.ShieldingDeviceLabel,
  '300a01a6': exports.ShieldingDeviceDescription,
  '300a01a8': exports.ShieldingDevicePosition,
  '300a01b0': exports.SetupTechnique,
  '300a01b2': exports.SetupTechniqueDescription,
  '300a01b4': exports.SetupDeviceSequence,
  '300a01b6': exports.SetupDeviceType,
  '300a01b8': exports.SetupDeviceLabel,
  '300a01ba': exports.SetupDeviceDescription,
  '300a01bc': exports.SetupDeviceParameter,
  '300a01d0': exports.SetupReferenceDescription,
  '300a01d2': exports.TableTopVerticalSetupDisplacement,
  '300a01d4': exports.TableTopLongitudinalSetupDisplacement,
  '300a01d6': exports.TableTopLateralSetupDisplacement,
  '300a0200': exports.BrachyTreatmentTechnique,
  '300a0202': exports.BrachyTreatmentType,
  '300a0206': exports.TreatmentMachineSequence,
  '300a0210': exports.SourceSequence,
  '300a0212': exports.SourceNumber,
  '300a0214': exports.SourceType,
  '300a0216': exports.SourceManufacturer,
  '300a0218': exports.ActiveSourceDiameter,
  '300a021a': exports.ActiveSourceLength,
  '300a021b': exports.SourceModelID,
  '300a021c': exports.SourceDescription,
  '300a0222': exports.SourceEncapsulationNominalThickness,
  '300a0224': exports.SourceEncapsulationNominalTransmission,
  '300a0226': exports.SourceIsotopeName,
  '300a0228': exports.SourceIsotopeHalfLife,
  '300a0229': exports.SourceStrengthUnits,
  '300a022a': exports.ReferenceAirKermaRate,
  '300a022b': exports.SourceStrength,
  '300a022c': exports.SourceStrengthReferenceDate,
  '300a022e': exports.SourceStrengthReferenceTime,
  '300a0230': exports.ApplicationSetupSequence,
  '300a0232': exports.ApplicationSetupType,
  '300a0234': exports.ApplicationSetupNumber,
  '300a0236': exports.ApplicationSetupName,
  '300a0238': exports.ApplicationSetupManufacturer,
  '300a0240': exports.TemplateNumber,
  '300a0242': exports.TemplateType,
  '300a0244': exports.TemplateName,
  '300a0250': exports.TotalReferenceAirKerma,
  '300a0260': exports.BrachyAccessoryDeviceSequence,
  '300a0262': exports.BrachyAccessoryDeviceNumber,
  '300a0263': exports.BrachyAccessoryDeviceID,
  '300a0264': exports.BrachyAccessoryDeviceType,
  '300a0266': exports.BrachyAccessoryDeviceName,
  '300a026a': exports.BrachyAccessoryDeviceNominalThickness,
  '300a026c': exports.BrachyAccessoryDeviceNominalTransmission,
  '300a0280': exports.ChannelSequence,
  '300a0282': exports.ChannelNumber,
  '300a0284': exports.ChannelLength,
  '300a0286': exports.ChannelTotalTime,
  '300a0288': exports.SourceMovementType,
  '300a028a': exports.NumberOfPulses,
  '300a028c': exports.PulseRepetitionInterval,
  '300a0290': exports.SourceApplicatorNumber,
  '300a0291': exports.SourceApplicatorID,
  '300a0292': exports.SourceApplicatorType,
  '300a0294': exports.SourceApplicatorName,
  '300a0296': exports.SourceApplicatorLength,
  '300a0298': exports.SourceApplicatorManufacturer,
  '300a029c': exports.SourceApplicatorWallNominalThickness,
  '300a029e': exports.SourceApplicatorWallNominalTransmission,
  '300a02a0': exports.SourceApplicatorStepSize,
  '300a02a2': exports.TransferTubeNumber,
  '300a02a4': exports.TransferTubeLength,
  '300a02b0': exports.ChannelShieldSequence,
  '300a02b2': exports.ChannelShieldNumber,
  '300a02b3': exports.ChannelShieldID,
  '300a02b4': exports.ChannelShieldName,
  '300a02b8': exports.ChannelShieldNominalThickness,
  '300a02ba': exports.ChannelShieldNominalTransmission,
  '300a02c8': exports.FinalCumulativeTimeWeight,
  '300a02d0': exports.BrachyControlPointSequence,
  '300a02d2': exports.ControlPointRelativePosition,
  '300a02d4': exports.ControlPoint3DPosition,
  '300a02d6': exports.CumulativeTimeWeight,
  '300a02e0': exports.CompensatorDivergence,
  '300a02e1': exports.CompensatorMountingPosition,
  '300a02e2': exports.SourceToCompensatorDistance,
  '300a02e3': exports.TotalCompensatorTrayWaterEquivalentThickness,
  '300a02e4': exports.IsocenterToCompensatorTrayDistance,
  '300a02e5': exports.CompensatorColumnOffset,
  '300a02e6': exports.IsocenterToCompensatorDistances,
  '300a02e7': exports.CompensatorRelativeStoppingPowerRatio,
  '300a02e8': exports.CompensatorMillingToolDiameter,
  '300a02ea': exports.IonRangeCompensatorSequence,
  '300a02eb': exports.CompensatorDescription,
  '300a0302': exports.RadiationMassNumber,
  '300a0304': exports.RadiationAtomicNumber,
  '300a0306': exports.RadiationChargeState,
  '300a0308': exports.ScanMode,
  '300a030a': exports.VirtualSourceAxisDistances,
  '300a030c': exports.SnoutSequence,
  '300a030d': exports.SnoutPosition,
  '300a030f': exports.SnoutID,
  '300a0312': exports.NumberOfRangeShifters,
  '300a0314': exports.RangeShifterSequence,
  '300a0316': exports.RangeShifterNumber,
  '300a0318': exports.RangeShifterID,
  '300a0320': exports.RangeShifterType,
  '300a0322': exports.RangeShifterDescription,
  '300a0330': exports.NumberOfLateralSpreadingDevices,
  '300a0332': exports.LateralSpreadingDeviceSequence,
  '300a0334': exports.LateralSpreadingDeviceNumber,
  '300a0336': exports.LateralSpreadingDeviceID,
  '300a0338': exports.LateralSpreadingDeviceType,
  '300a033a': exports.LateralSpreadingDeviceDescription,
  '300a033c': exports.LateralSpreadingDeviceWaterEquivalentThickness,
  '300a0340': exports.NumberOfRangeModulators,
  '300a0342': exports.RangeModulatorSequence,
  '300a0344': exports.RangeModulatorNumber,
  '300a0346': exports.RangeModulatorID,
  '300a0348': exports.RangeModulatorType,
  '300a034a': exports.RangeModulatorDescription,
  '300a034c': exports.BeamCurrentModulationID,
  '300a0350': exports.PatientSupportType,
  '300a0352': exports.PatientSupportID,
  '300a0354': exports.PatientSupportAccessoryCode,
  '300a0356': exports.FixationLightAzimuthalAngle,
  '300a0358': exports.FixationLightPolarAngle,
  '300a035a': exports.MetersetRate,
  '300a0360': exports.RangeShifterSettingsSequence,
  '300a0362': exports.RangeShifterSetting,
  '300a0364': exports.IsocenterToRangeShifterDistance,
  '300a0366': exports.RangeShifterWaterEquivalentThickness,
  '300a0370': exports.LateralSpreadingDeviceSettingsSequence,
  '300a0372': exports.LateralSpreadingDeviceSetting,
  '300a0374': exports.IsocenterToLateralSpreadingDeviceDistance,
  '300a0380': exports.RangeModulatorSettingsSequence,
  '300a0382': exports.RangeModulatorGatingStartValue,
  '300a0384': exports.RangeModulatorGatingStopValue,
  '300a0386': exports.RangeModulatorGatingStartWaterEquivalentThickness,
  '300a0388': exports.RangeModulatorGatingStopWaterEquivalentThickness,
  '300a038a': exports.IsocenterToRangeModulatorDistance,
  '300a0390': exports.ScanSpotTuneID,
  '300a0392': exports.NumberOfScanSpotPositions,
  '300a0394': exports.ScanSpotPositionMap,
  '300a0396': exports.ScanSpotMetersetWeights,
  '300a0398': exports.ScanningSpotSize,
  '300a039a': exports.NumberOfPaintings,
  '300a03a0': exports.IonToleranceTableSequence,
  '300a03a2': exports.IonBeamSequence,
  '300a03a4': exports.IonBeamLimitingDeviceSequence,
  '300a03a6': exports.IonBlockSequence,
  '300a03a8': exports.IonControlPointSequence,
  '300a03aa': exports.IonWedgeSequence,
  '300a03ac': exports.IonWedgePositionSequence,
  '300a0401': exports.ReferencedSetupImageSequence,
  '300a0402': exports.SetupImageComment,
  '300a0410': exports.MotionSynchronizationSequence,
  '300a0412': exports.ControlPointOrientation,
  '300a0420': exports.GeneralAccessorySequence,
  '300a0421': exports.GeneralAccessoryID,
  '300a0422': exports.GeneralAccessoryDescription,
  '300a0423': exports.GeneralAccessoryType,
  '300a0424': exports.GeneralAccessoryNumber,
  '300a0425': exports.SourceToGeneralAccessoryDistance,
  '300a0431': exports.ApplicatorGeometrySequence,
  '300a0432': exports.ApplicatorApertureShape,
  '300a0433': exports.ApplicatorOpening,
  '300a0434': exports.ApplicatorOpeningX,
  '300a0435': exports.ApplicatorOpeningY,
  '300a0436': exports.SourceToApplicatorMountingPositionDistance,
  '300c0002': exports.ReferencedRTPlanSequence,
  '300c0004': exports.ReferencedBeamSequence,
  '300c0006': exports.ReferencedBeamNumber,
  '300c0007': exports.ReferencedReferenceImageNumber,
  '300c0008': exports.StartCumulativeMetersetWeight,
  '300c0009': exports.EndCumulativeMetersetWeight,
  '300c000a': exports.ReferencedBrachyApplicationSetupSequence,
  '300c000c': exports.ReferencedBrachyApplicationSetupNumber,
  '300c000e': exports.ReferencedSourceNumber,
  '300c0020': exports.ReferencedFractionGroupSequence,
  '300c0022': exports.ReferencedFractionGroupNumber,
  '300c0040': exports.ReferencedVerificationImageSequence,
  '300c0042': exports.ReferencedReferenceImageSequence,
  '300c0050': exports.ReferencedDoseReferenceSequence,
  '300c0051': exports.ReferencedDoseReferenceNumber,
  '300c0055': exports.BrachyReferencedDoseReferenceSequence,
  '300c0060': exports.ReferencedStructureSetSequence,
  '300c006a': exports.ReferencedPatientSetupNumber,
  '300c0080': exports.ReferencedDoseSequence,
  '300c00a0': exports.ReferencedToleranceTableNumber,
  '300c00b0': exports.ReferencedBolusSequence,
  '300c00c0': exports.ReferencedWedgeNumber,
  '300c00d0': exports.ReferencedCompensatorNumber,
  '300c00e0': exports.ReferencedBlockNumber,
  '300c00f0': exports.ReferencedControlPointIndex,
  '300c00f2': exports.ReferencedControlPointSequence,
  '300c00f4': exports.ReferencedStartControlPointIndex,
  '300c00f6': exports.ReferencedStopControlPointIndex,
  '300c0100': exports.ReferencedRangeShifterNumber,
  '300c0102': exports.ReferencedLateralSpreadingDeviceNumber,
  '300c0104': exports.ReferencedRangeModulatorNumber,
  '300e0002': exports.ApprovalStatus,
  '300e0004': exports.ReviewDate,
  '300e0005': exports.ReviewTime,
  '300e0008': exports.ReviewerName,
  '40000010': exports.Arbitrary,
  '40004000': exports.TextComments,
  '40080040': exports.ResultsID,
  '40080042': exports.ResultsIDIssuer,
  '40080050': exports.ReferencedInterpretationSequence,
  '400800ff': exports.ReportProductionStatusTrial,
  '40080100': exports.InterpretationRecordedDate,
  '40080101': exports.InterpretationRecordedTime,
  '40080102': exports.InterpretationRecorder,
  '40080103': exports.ReferenceToRecordedSound,
  '40080108': exports.InterpretationTranscriptionDate,
  '40080109': exports.InterpretationTranscriptionTime,
  '4008010a': exports.InterpretationTranscriber,
  '4008010b': exports.InterpretationText,
  '4008010c': exports.InterpretationAuthor,
  '40080111': exports.InterpretationApproverSequence,
  '40080112': exports.InterpretationApprovalDate,
  '40080113': exports.InterpretationApprovalTime,
  '40080114': exports.PhysicianApprovingInterpretation,
  '40080115': exports.InterpretationDiagnosisDescription,
  '40080117': exports.InterpretationDiagnosisCodeSequence,
  '40080118': exports.ResultsDistributionListSequence,
  '40080119': exports.DistributionName,
  '4008011a': exports.DistributionAddress,
  '40080200': exports.InterpretationID,
  '40080202': exports.InterpretationIDIssuer,
  '40080210': exports.InterpretationTypeID,
  '40080212': exports.InterpretationStatusID,
  '40080300': exports.Impressions,
  '40084000': exports.ResultsComments,
  '40100001': exports.LowEnergyDetectors,
  '40100002': exports.HighEnergyDetectors,
  '40100004': exports.DetectorGeometrySequence,
  '40101001': exports.ThreatROIVoxelSequence,
  '40101004': exports.ThreatROIBase,
  '40101005': exports.ThreatROIExtents,
  '40101006': exports.ThreatROIBitmap,
  '40101007': exports.RouteSegmentID,
  '40101008': exports.GantryType,
  '40101009': exports.OOIOwnerType,
  '4010100a': exports.RouteSegmentSequence,
  '40101010': exports.PotentialThreatObjectID,
  '40101011': exports.ThreatSequence,
  '40101012': exports.ThreatCategory,
  '40101013': exports.ThreatCategoryDescription,
  '40101014': exports.ATDAbilityAssessment,
  '40101015': exports.ATDAssessmentFlag,
  '40101016': exports.ATDAssessmentProbability,
  '40101017': exports.Mass,
  '40101018': exports.Density,
  '40101019': exports.ZEffective,
  '4010101a': exports.BoardingPassID,
  '4010101b': exports.CenterOfMass,
  '4010101c': exports.CenterOfPTO,
  '4010101d': exports.BoundingPolygon,
  '4010101e': exports.RouteSegmentStartLocationID,
  '4010101f': exports.RouteSegmentEndLocationID,
  '40101020': exports.RouteSegmentLocationIDType,
  '40101021': exports.AbortReason,
  '40101023': exports.VolumeOfPTO,
  '40101024': exports.AbortFlag,
  '40101025': exports.RouteSegmentStartTime,
  '40101026': exports.RouteSegmentEndTime,
  '40101027': exports.TDRType,
  '40101028': exports.InternationalRouteSegment,
  '40101029': exports.ThreatDetectionAlgorithmandVersion,
  '4010102a': exports.AssignedLocation,
  '4010102b': exports.AlarmDecisionTime,
  '40101031': exports.AlarmDecision,
  '40101033': exports.NumberOfTotalObjects,
  '40101034': exports.NumberOfAlarmObjects,
  '40101037': exports.PTORepresentationSequence,
  '40101038': exports.ATDAssessmentSequence,
  '40101039': exports.TIPType,
  '4010103a': exports.DICOSVersion,
  '40101041': exports.OOIOwnerCreationTime,
  '40101042': exports.OOIType,
  '40101043': exports.OOISize,
  '40101044': exports.AcquisitionStatus,
  '40101045': exports.BasisMaterialsCodeSequence,
  '40101046': exports.PhantomType,
  '40101047': exports.OOIOwnerSequence,
  '40101048': exports.ScanType,
  '40101051': exports.ItineraryID,
  '40101052': exports.ItineraryIDType,
  '40101053': exports.ItineraryIDAssigningAuthority,
  '40101054': exports.RouteID,
  '40101055': exports.RouteIDAssigningAuthority,
  '40101056': exports.InboundArrivalType,
  '40101058': exports.CarrierID,
  '40101059': exports.CarrierIDAssigningAuthority,
  '40101060': exports.SourceOrientation,
  '40101061': exports.SourcePosition,
  '40101062': exports.BeltHeight,
  '40101064': exports.AlgorithmRoutingCodeSequence,
  '40101067': exports.TransportClassification,
  '40101068': exports.OOITypeDescriptor,
  '40101069': exports.TotalProcessingTime,
  '4010106c': exports.DetectorCalibrationData,
  '4010106d': exports.AdditionalScreeningPerformed,
  '4010106e': exports.AdditionalInspectionSelectionCriteria,
  '4010106f': exports.AdditionalInspectionMethodSequence,
  '40101070': exports.AITDeviceType,
  '40101071': exports.QRMeasurementsSequence,
  '40101072': exports.TargetMaterialSequence,
  '40101073': exports.SNRThreshold,
  '40101075': exports.ImageScaleRepresentation,
  '40101076': exports.ReferencedPTOSequence,
  '40101077': exports.ReferencedTDRInstanceSequence,
  '40101078': exports.PTOLocationDescription,
  '40101079': exports.AnomalyLocatorIndicatorSequence,
  '4010107a': exports.AnomalyLocatorIndicator,
  '4010107b': exports.PTORegionSequence,
  '4010107c': exports.InspectionSelectionCriteria,
  '4010107d': exports.SecondaryInspectionMethodSequence,
  '4010107e': exports.PRCSToRCSOrientation,
  '4ffe0001': exports.MACParametersSequence,
  '50000005': exports.CurveDimensions,
  '50000010': exports.NumberOfPoints,
  '50000020': exports.TypeOfData,
  '50000022': exports.CurveDescription,
  '50000030': exports.AxisUnits,
  '50000040': exports.AxisLabels,
  '50000103': exports.DataValueRepresentation,
  '50000104': exports.MinimumCoordinateValue,
  '50000105': exports.MaximumCoordinateValue,
  '50000106': exports.CurveRange,
  '50000110': exports.CurveDataDescriptor,
  '50000112': exports.CoordinateStartValue,
  '50000114': exports.CoordinateStepValue,
  '50001001': exports.CurveActivationLayer,
  '50002000': exports.AudioType,
  '50002002': exports.AudioSampleFormat,
  '50002004': exports.NumberOfChannels,
  '50002006': exports.NumberOfSamples,
  '50002008': exports.SampleRate,
  '5000200a': exports.TotalTime,
  '5000200c': exports.AudioSampleData,
  '5000200e': exports.AudioComments,
  '50002500': exports.CurveLabel,
  '50002600': exports.CurveReferencedOverlaySequence,
  '50002610': exports.CurveReferencedOverlayGroup,
  '50003000': exports.CurveData,
  '52009229': exports.SharedFunctionalGroupsSequence,
  '52009230': exports.PerFrameFunctionalGroupsSequence,
  '54000100': exports.WaveformSequence,
  '54000110': exports.ChannelMinimumValue,
  '54000112': exports.ChannelMaximumValue,
  '54001004': exports.WaveformBitsAllocated,
  '54001006': exports.WaveformSampleInterpretation,
  '5400100a': exports.WaveformPaddingValue,
  '54001010': exports.WaveformData,
  '56000010': exports.FirstOrderPhaseCorrectionAngle,
  '56000020': exports.SpectroscopyData,
  '60000010': exports.OverlayRows,
  '60000011': exports.OverlayColumns,
  '60000012': exports.OverlayPlanes,
  '60000015': exports.NumberOfFramesInOverlay,
  '60000022': exports.OverlayDescription,
  '60000040': exports.OverlayType,
  '60000045': exports.OverlaySubtype,
  '60000050': exports.OverlayOrigin,
  '60000051': exports.ImageFrameOrigin,
  '60000052': exports.OverlayPlaneOrigin,
  '60000060': exports.OverlayCompressionCode,
  '60000061': exports.OverlayCompressionOriginator,
  '60000062': exports.OverlayCompressionLabel,
  '60000063': exports.OverlayCompressionDescription,
  '60000066': exports.OverlayCompressionStepPointers,
  '60000068': exports.OverlayRepeatInterval,
  '60000069': exports.OverlayBitsGrouped,
  '60000100': exports.OverlayBitsAllocated,
  '60000102': exports.OverlayBitPosition,
  '60000110': exports.OverlayFormat,
  '60000200': exports.OverlayLocation,
  '60000800': exports.OverlayCodeLabel,
  '60000802': exports.OverlayNumberOfTables,
  '60000803': exports.OverlayCodeTableLocation,
  '60000804': exports.OverlayBitsForCodeWord,
  '60001001': exports.OverlayActivationLayer,
  '60001100': exports.OverlayDescriptorGray,
  '60001101': exports.OverlayDescriptorRed,
  '60001102': exports.OverlayDescriptorGreen,
  '60001103': exports.OverlayDescriptorBlue,
  '60001200': exports.OverlaysGray,
  '60001201': exports.OverlaysRed,
  '60001202': exports.OverlaysGreen,
  '60001203': exports.OverlaysBlue,
  '60001301': exports.ROIArea,
  '60001302': exports.ROIMean,
  '60001303': exports.ROIStandardDeviation,
  '60001500': exports.OverlayLabel,
  '60003000': exports.OverlayData,
  '60004000': exports.OverlayComments,
  '7fe00010': exports.PixelData,
  '7fe00020': exports.CoefficientsSDVN,
  '7fe00030': exports.CoefficientsSDHN,
  '7fe00040': exports.CoefficientsSDDN,
  '7f000010': exports.VariablePixelData,
  '7f000011': exports.VariableNextDataGroup,
  '7f000020': exports.VariableCoefficientsSDVN,
  '7f000030': exports.VariableCoefficientsSDHN,
  '7f000040': exports.VariableCoefficientsSDDN,
  'fffafffa': exports.DigitalSignaturesSequence,
  'fffcfffc': exports.DataSetTrailingPadding,
  'fffee000': exports.Item,
  'fffee00d': exports.ItemDelimitationItem,
  'fffee0dd': exports.SequenceDelimitationItem,
_TAG_MASKS = [
   [1, 0xffffff0f, 0x00280400],
   [1, 0xffffff0f, 0x00280401],
   [1, 0xffffff0f, 0x00280402],
   [1, 0xffffff0f, 0x00280403],
   [1, 0xffffff0f, 0x00280800],
   [1, 0xffffff0f, 0x00280802],
   [1, 0xffffff0f, 0x00280803],
   [1, 0xffffff0f, 0x00280804],
   [1, 0xffffff0f, 0x00280808],
   [2, 0xff00ffff, 0x50000005],
   [2, 0xff00ffff, 0x50000010],
   [2, 0xff00ffff, 0x50000020],
   [2, 0xff00ffff, 0x50000022],
   [2, 0xff00ffff, 0x50000030],
   [2, 0xff00ffff, 0x50000040],
   [2, 0xff00ffff, 0x50000103],
   [2, 0xff00ffff, 0x50000104],
   [2, 0xff00ffff, 0x50000105],
   [2, 0xff00ffff, 0x50000106],
   [2, 0xff00ffff, 0x50000110],
   [2, 0xff00ffff, 0x50000112],
   [2, 0xff00ffff, 0x50000114],
   [2, 0xff00ffff, 0x50001001],
   [2, 0xff00ffff, 0x50002000],
   [2, 0xff00ffff, 0x50002002],
   [2, 0xff00ffff, 0x50002004],
   [2, 0xff00ffff, 0x50002006],
   [2, 0xff00ffff, 0x50002008],
   [2, 0xff00ffff, 0x5000200a],
   [2, 0xff00ffff, 0x5000200c],
   [2, 0xff00ffff, 0x5000200e],
   [2, 0xff00ffff, 0x50002500],
   [2, 0xff00ffff, 0x50002600],
   [2, 0xff00ffff, 0x50002610],
   [2, 0xff00ffff, 0x50003000],
   [2, 0xff00ffff, 0x60000010],
   [2, 0xff00ffff, 0x60000011],
   [2, 0xff00ffff, 0x60000012],
   [2, 0xff00ffff, 0x60000015],
   [2, 0xff00ffff, 0x60000022],
   [2, 0xff00ffff, 0x60000040],
   [2, 0xff00ffff, 0x60000045],
   [2, 0xff00ffff, 0x60000050],
   [2, 0xff00ffff, 0x60000051],
   [2, 0xff00ffff, 0x60000052],
   [2, 0xff00ffff, 0x60000060],
   [2, 0xff00ffff, 0x60000061],
   [2, 0xff00ffff, 0x60000062],
   [2, 0xff00ffff, 0x60000063],
   [2, 0xff00ffff, 0x60000066],
   [2, 0xff00ffff, 0x60000068],
   [2, 0xff00ffff, 0x60000069],
   [2, 0xff00ffff, 0x60000100],
   [2, 0xff00ffff, 0x60000102],
   [2, 0xff00ffff, 0x60000110],
   [2, 0xff00ffff, 0x60000200],
   [2, 0xff00ffff, 0x60000800],
   [2, 0xff00ffff, 0x60000802],
   [2, 0xff00ffff, 0x60000803],
   [2, 0xff00ffff, 0x60000804],
   [2, 0xff00ffff, 0x60001001],
   [2, 0xff00ffff, 0x60001100],
   [2, 0xff00ffff, 0x60001101],
   [2, 0xff00ffff, 0x60001102],
   [2, 0xff00ffff, 0x60001103],
   [2, 0xff00ffff, 0x60001200],
   [2, 0xff00ffff, 0x60001201],
   [2, 0xff00ffff, 0x60001202],
   [2, 0xff00ffff, 0x60001203],
   [2, 0xff00ffff, 0x60001301],
   [2, 0xff00ffff, 0x60001302],
   [2, 0xff00ffff, 0x60001303],
   [2, 0xff00ffff, 0x60001500],
   [2, 0xff00ffff, 0x60003000],
   [2, 0xff00ffff, 0x60004000],
   [2, 0xff00ffff, 0x7f000010],
   [2, 0xff00ffff, 0x7f000011],
   [2, 0xff00ffff, 0x7f000020],
   [2, 0xff00ffff, 0x7f000030],
   [2, 0xff00ffff, 0x7f000040],
   [2, 0xffffff00, 0x00203100],
]
