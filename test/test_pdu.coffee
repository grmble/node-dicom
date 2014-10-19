#! /usr/bin/env /coffee

pdu = require "../lib/pdu"

ECHO_RAW =[ 1, 0, 0, 0, 0, 197, 0, 1, 0, 0, 84, 69, 83,
            84, 77, 69, 32, 32, 32, 32, 32, 32, 32, 32, 32,
            32, 68, 67, 77, 69, 67, 72, 79, 32, 32, 32, 32,
            32, 32, 32, 32, 32, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 21, 49, 46,
            50, 46, 56, 52, 48, 46, 49, 48, 48, 48, 56, 46,
            51, 46, 49, 46, 49, 46, 49, 32, 0, 0, 46, 1,
            0, 0, 0, 48, 0, 0, 17, 49, 46, 50, 46, 56, 52,
            48, 46, 49, 48, 48, 48, 56, 46, 49, 46, 49,
            64, 0, 0, 17, 49, 46, 50, 46, 56, 52, 48, 46,
            49, 48, 48, 48, 56, 46, 49, 46, 50, 80, 0,
            0, 50, 81, 0, 0, 4, 0, 0, 64, 0, 82, 0, 0, 15,
            49, 46, 50, 46, 52, 48, 46, 48, 46, 49,
            51, 46, 49, 46, 49, 83, 0, 0, 4, 0, 0, 0, 0, 85,
            0, 0, 11, 100, 99, 109, 52, 99, 104, 101,
            45, 50, 46, 48 ]
ECHO_PDU = {
  "name": "association_rq",
  "called_aet_title": "TESTME",
  "calling_aet_title": "DCMECHO",
  "application_context": "1.2.840.10008.3.1.1.1"
  "presentation_context": [
    "id": 1,
    "abstract_syntax": "1.2.840.10008.1.1",
    "transfer_syntax": ["1.2.840.10008.1.2"]]
  "user_information":
    "maximum_length": 16384
    "implementation_class_uid": "1.2.40.0.13.1.1"
    "asynchronous_operations_window":
        "maximum_number_operations_invoked": 0
        "maximum_number_operations_performed": 0
    "implementation_version_name": "dcm4che-2.0"
}

exports.PDUTest =
  "test decoding echo association request": (test) ->
    test.expect 1

    _decoder = new pdu.PDUDecoder()
    _decoder.on 'data', (pdu) ->
      test.deepEqual ECHO_PDU, pdu.to_json()
      test.done()
    _decoder.write(new Buffer(ECHO_RAW))

  "test encoding echo association request": (test) ->
    test.expect 1

    _encoder = new pdu.PDUEncoder()
    _encoder.on 'data', (buff) ->
      _decoder = new pdu.PDUDecoder()
      _decoder.on 'data', (pdu) ->
        test.deepEqual ECHO_PDU, pdu.to_json()
        test.done()
      _decoder.write buff
    _encoder.write new pdu.PDUAssociateRq(ECHO_PDU)