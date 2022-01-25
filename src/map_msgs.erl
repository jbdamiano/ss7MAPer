-module(map_msgs).
-author('Daniel Mende <mail@c0decafe.de>').

-include_lib("osmo_map/src/map.hrl").
-include("ss7MAPer.hrl").

-compile([export_all]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% default values msgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SCCP Definitions
-define(LOCAL_GLOBAL_TITLE,     [1,2,3,4,5,6,7,8,9]).
-define(REMOTE_GLOBAL_TITLE,    [1,2,3,4,5,6,7,8,0]).
-define(NI,                     2).

% MAP Definitions
-define(IMSI,                       hex:hexstr_to_bin("01020304050607f8")).
-define(IMSI_AS_NR,                 ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_LAND_MOBILE,
                                        [0,1,0,2,0,3,0,4,0,5,0,6,0,7,8])).
-define(TMSI,                       hex:hexstr_to_bin("1234")).

-define(MSISDN,                     ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                                        [1,2,3,4,5,6,7,8,9,0])).

-define(SERVICE_CENTER_ADDRESS,     hex:hexstr_to_bin("010203040506f1")).
-define(SERVICE_CENTER_ADDRESS_OA,  hex:hexstr_to_bin("010203040506f1")).
-define(SERVICE_CENTER_ADDRESS_DA,  hex:hexstr_to_bin("010203040506f1")).
-define(GGSN,                       ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                                        [1,2,3,4,5,6,7,8,9,0])).



% SMS Definitions
-define(ORIGINATING_ADDRESS,        hex:hexstr_to_bin("0b9010203040506f1")).
-define(DESTINATION_ADDRESS,        ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                                        [1,2,3,4,5,6,7,8,9,0])).
-define(SOURCE_ADDRESS,             ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                                        [1,2,3,4,5,6,7,8,9,0])).
-define(SMS_DEST_NR,                [1,2,3,4,5,6,7,8,9,0]).
-define(SMS_SRC_NR,                 [1,2,3,4,5,6,7,8,9,0]).

-define(IMEI,                       ss7_helper:encode_phonenumner([1,2,3,4,5,6,7,8,9,0])).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

get_transactionId() ->
    <<1,1,0,0>>.

build_dialog_request(Context) ->
    build_dialog_request(Context, asn1_NOVALUE).
build_dialog_request(Context, Extra) ->
    DialoguePDU = {'dialogueRequest',
        {'AARQ-apdu',
            [version1],
            Context,
            Extra}},
    {ok, EncDialoguePDU} = map:encode('DialoguePDU', DialoguePDU),
    EncDialoguePDU.

encode_map_pdu(Dialog, Local, MapData) ->
    MapPDU = {'begin',                                                             
        {'MapSpecificPDUs_begin',
            get_transactionId(),
            {'EXTERNAL',
                ?'dialogue-as-id',
                asn1_NOVALUE,asn1_NOVALUE,
                {'single-ASN1-type', Dialog}},
            [{basicROS,
                 {invoke,
                     {'MapSpecificPDUs_begin_components_SEQOF_basicROS_invoke',
                         {present,1},
                         asn1_NOVALUE,
                         {local,Local},
                         MapData}}}]}},
    {ok, EncMapPDU} = map:encode('MapSpecificPDUs', MapPDU),
    EncMapPDU.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_testSMSPDU_mt() ->
    SMSText = "ERNW test SMS 31337",
    EncSMSText = 'sms_7bit_encoding':to_7bit(SMSText),
    SMSLen = string:len(SMSText),
    Timestamp = hex:hexstr_to_bin("51803001258080"),
    DA = ss7_helper:encode_phonenumber(?NUMBER_EXTENSION_NONE,
            ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
            ?SMS_SRC_NR),
    <<0:4, 4:4, DA/binary, 0:8, 0:8, Timestamp/binary, SMSLen:8, EncSMSText/binary>>.

create_testSMSPDU_mo() ->
    SMSText = "ERNW test SMS 31337",
    EncSMSText = 'sms_7bit_encoding':to_7bit(SMSText),
    SMSLen = string:len(SMSText),
    DA = ss7_helper:encode_phonenumber(?NUMBER_EXTENSION_NONE,
            ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
            ?SMS_DEST_NR),
    <<1:8, 23:8, DA/binary, 0:8, 0:8, SMSLen:8, EncSMSText/binary>>.

create_mt_forwardSM_v2() ->
    create_mt_forwardSM_v2(create_testSMSPDU_mt(), ?IMSI, ?SERVICE_CENTER_ADDRESS_DA).
create_mt_forwardSM_v2(SMSPDU, Imsi, Scada) ->
    MapData = { 'ForwardSM-Arg',
                {imsi, ss7_helper:encode_imsi(Imsi)},
                {serviceCentreAddressOA, ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                    ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                    Scada)},
                SMSPDU,
                asn1_NOVALUE, asn1_NOVALUE},
    Dialog = build_dialog_request({0,4,0,0,1,0,25,2}),
    encode_map_pdu(Dialog, 46, MapData).

create_mt_forwardSM() ->
    create_mt_forwardSM(create_testSMSPDU_mt()).
create_mt_forwardSM(SMSPDU) ->
    MapData = {'MT-ForwardSM-Arg',
               {serviceCentreAddressDA, ?SERVICE_CENTER_ADDRESS_DA},
               {msisdn, ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                    ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                    ?SOURCE_ADDRESS)},
               SMSPDU,
               asn1_NOVALUE,    %moreMessagesToSend
               asn1_NOVALUE     %extensionContainer
               },
    Dialog = build_dialog_request(?'shortMsgMT-RelayContext-v3'),
    encode_map_pdu(Dialog, 44, MapData).
    
create_mo_forwardSM_v2() ->
    create_mo_forwardSM_v2(create_testSMSPDU_mo(), ?SERVICE_CENTER_ADDRESS_DA, ?MSISDN).
create_mo_forwardSM_v2(SMSPDU, Scada, Msisdn) ->
    MapData = { 'ForwardSM-Arg',
                {serviceCentreAddressDA, ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                    ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                    Scada)},
                {msisdn, ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                    ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                    Msisdn)},
                SMSPDU,
                asn1_NOVALUE, asn1_NOVALUE},
    Dialog = build_dialog_request({0,4,0,0,1,0,21,2}),
    encode_map_pdu(Dialog, 46, MapData).

create_mo_forwardSM() ->
    create_mo_forwardSM(create_testSMSPDU_mo()).
create_mo_forwardSM(SMSPDU) ->
    MapData = {'MO-ForwardSM-Arg',
                 {serviceCentreAddressDA, ?SERVICE_CENTER_ADDRESS_DA},
                 {msisdn, ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                    ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                    ?MSISDN)},
                 SMSPDU,
                 asn1_NOVALUE,
                 asn1_NOVALUE  % ?IMSI_FROM
                   },
    Dialog = build_dialog_request(?'shortMsgMO-RelayContext-v3'),
    encode_map_pdu(Dialog, 46, MapData).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% to HLR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
create_sendRoutingInfoForSM() ->
    create_sendRoutingInfoForSM(?MSISDN, ?SERVICE_CENTER_ADDRESS).
create_sendRoutingInfoForSM(Msisdn, Ssaddr) ->
    MapData = { 'send-routing-info-for-sm-arg',
                ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                    ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                    Msisdn),
                false,
                ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                    ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                    Ssaddr),
                asn1_NOVALUE,
                asn1_NOVALUE, %true,
                asn1_NOVALUE, %0,
                asn1_NOVALUE, %hex:hexstr_to_bin("0b912374140404f7"),
                asn1_NOVALUE},
    MapPDU = {'begin',
              {'MapSpecificPDUs_begin',
               get_transactionId(), 
               {'EXTERNAL',
                {0,0,17,773,1,1,1},
                asn1_NOVALUE,
                asn1_NOVALUE,
                {'single-ASN1-type',<<96,11,161,9,6,7,4,0,0,1,0,20,3>>}}, 
               [{'basicROS', 
                 {'invoke',
                  {'MapSpecificPDUs_begin_components_SEQOF_basicROS_invoke',
                   {'present', 1},
                   asn1_NOVALUE, 
                   {'local', 45}, 
                   MapData}}}]}},
    {ok, EncMapPDU} = map:encode('MapSpecificPDUs', MapPDU),
    EncMapPDU.

create_sendRoutingInfo() ->
    create_sendRoutingInfo(?MSISDN, ?LOCAL_GLOBAL_TITLE).
create_sendRoutingInfo(Msisdn, OrGsmSCF) ->
    MapData = {'SendRoutingInfoArg',
                ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                    ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                    Msisdn),
                asn1_NOVALUE,
                asn1_NOVALUE,
                basicCall,
                asn1_NOVALUE,
                asn1_NOVALUE,
                ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                        OrGsmSCF),     %gsmc-OrGsmSCF-Address
                <<7,0,1,68,40,9,150,31>>,   %callReferenceNumber
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                {'CamelInfo',
                    [phase1,phase2,phase3,phase4],
                    asn1_NOVALUE,
                    asn1_NOVALUE,
                    ['o-csi','d-csi','t-csi']},
                asn1_NOVALUE,
                {'ExtensionContainer',
                    [{'PrivateExtension',{1,2,826,0,1249,58,1,0},<<164,5,48,3,129,1,6>>}, %Nokia ExtensionType Extension
                     {'PrivateExtension',{0,34,5},<<224,2,132,0>>}],    %Nokia srbtSupportIndicator
                    asn1_NOVALUE},
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE, %'NULL',
                asn1_NOVALUE,
                asn1_NOVALUE, %'NULL',
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE},
    MapPDU = {'begin',
        {'MapSpecificPDUs_begin',
            get_transactionId(), 
            {'EXTERNAL',
                {0,0,17,773,1,1,1},
                asn1_NOVALUE,asn1_NOVALUE,
                {'single-ASN1-type',
                    <<96,15,128,2,7,128,161,9,6,7,4,0,0,1,0,5,3>>}},
            [{basicROS,
                 {invoke,
                     {'MapSpecificPDUs_begin_components_SEQOF_basicROS_invoke',
                         {present,1},
                         asn1_NOVALUE,
                         {local,22},
                         MapData}}}]}},
    {ok, EncMapPDU} = map:encode('MapSpecificPDUs', MapPDU),
    EncMapPDU.

create_registerSS(Imsi, Origin, DestinationNumber) ->
    MapDialoguePDU = {'map-open',
                    {'MAP-OpenInfo',
                        ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                            ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_LAND_MOBILE,
                            Imsi),    %destinationReference
                        ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                            ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                            Origin),   %originationReference
                        asn1_NOVALUE }},
    {ok, EncMapDialoguePDU} = map:encode('MAP-DialoguePDU', MapDialoguePDU),
    DialoguePDU = {'dialogueRequest',
                    {'AARQ-apdu',
                        [version1],
                        ?'networkFunctionalSsContext-v2', %?'ss-InvocationNotificationContext-v3',
                        [{'EXTERNAL',
                            ?'map-DialogueAS',
                            asn1_NOVALUE,asn1_NOVALUE,
                            {'single-ASN1-type',
                                EncMapDialoguePDU}}]}},
    {ok, EncDialoguePDU} = map:encode('DialoguePDU', DialoguePDU),
    MapData = {'RegisterSS-Arg',
                ?allForwardingSS,    %ss-Code
                asn1_NOVALUE,
                ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                    ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                    DestinationNumber),   %forwardedToNumber
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE},
    MapPDU = {'begin',                           
        {'MapSpecificPDUs_begin',
            get_transactionId(),
            {'EXTERNAL',
                ?'dialogue-as-id',
                asn1_NOVALUE,asn1_NOVALUE,
                {'single-ASN1-type',
                    EncDialoguePDU
                    }},
            [{basicROS,
                 {invoke,
                     {'MapSpecificPDUs_begin_components_SEQOF_basicROS_invoke',
                         {present,1},
                         asn1_NOVALUE,
                         {local,10},
                         MapData}}}]}},
    {ok, EncMapPDU} = map:encode('MapSpecificPDUs', MapPDU),
    EncMapPDU.

create_eraseSS(Imsi, Origin) ->
    MapDialoguePDU = {'map-open',
                    {'MAP-OpenInfo',
                        ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                            ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_LAND_MOBILE,
                            Imsi),    %destinationReference
                        ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                            ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                            Origin),   %originationReference
                        asn1_NOVALUE }},
    {ok, EncMapDialoguePDU} = map:encode('MAP-DialoguePDU', MapDialoguePDU),
    DialoguePDU = {'dialogueRequest',
                    {'AARQ-apdu',
                        [version1],
                        ?'networkFunctionalSsContext-v2', %?'ss-InvocationNotificationContext-v3',
                        [{'EXTERNAL',
                            ?'map-DialogueAS',
                            asn1_NOVALUE,asn1_NOVALUE,
                            {'single-ASN1-type',
                                EncMapDialoguePDU}}]}},
    {ok, EncDialoguePDU} = map:encode('DialoguePDU', DialoguePDU),
    MapData = {'SS-ForBS-Code-Arg',
                ?allForwardingSS,   %ss-Code
                asn1_NOVALUE,       %basicService
                asn1_NOVALUE},      %longFTN-Supported
    MapPDU = {'begin',                           
        {'MapSpecificPDUs_begin',
            get_transactionId(),
            {'EXTERNAL',
                ?'dialogue-as-id',
                asn1_NOVALUE,asn1_NOVALUE,
                {'single-ASN1-type',
                    EncDialoguePDU
                    }},
            [{basicROS,
                 {invoke,
                     {'MapSpecificPDUs_begin_components_SEQOF_basicROS_invoke',
                         {present,1},
                         asn1_NOVALUE,
                         {local,11},
                         MapData}}}]}},
    {ok, EncMapPDU} = map:encode('MapSpecificPDUs', MapPDU),
    EncMapPDU.

create_updateLocation() ->
    create_updateLocation(?IMSI, ?LOCAL_GLOBAL_TITLE, ?LOCAL_GLOBAL_TITLE).
create_updateLocation(Imsi, MscNr, VlrNr) ->
    MapData = {'UpdateLocationArg',
                ss7_helper:encode_imsi(Imsi),
                ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                        MscNr),     %msc-Number
                ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                        VlrNr),     %vlr-Number
                asn1_NOVALUE, %<<59,151,2,0>>,             %lmsi
                asn1_NOVALUE,
                {'VLR-Capability',
                    [phase1,phase2,phase3,phase4],
                    asn1_NOVALUE,asn1_NOVALUE,asn1_NOVALUE,
                    asn1_NOVALUE,'NULL',
                    [lcsCapabilitySet1,lcsCapabilitySet2],
                    ['o-csi','d-csi','vt-csi','mt-sms-csi'],
                    asn1_NOVALUE,asn1_NOVALUE},
                asn1_NOVALUE,asn1_NOVALUE,asn1_NOVALUE,
                asn1_NOVALUE,asn1_NOVALUE,asn1_NOVALUE,
                'NULL'},
    MapPDU = {'begin',
        {'MapSpecificPDUs_begin',
            get_transactionId(),
            {'EXTERNAL',
                ?'dialogue-as-id',
                asn1_NOVALUE,asn1_NOVALUE,
                {'single-ASN1-type',
                    <<96,15,128,2,7,128,161,9,6,7,4,0,0,1,0,1,3>>}},
            [{basicROS,
                 {invoke,
                     {'MapSpecificPDUs_begin_components_SEQOF_basicROS_invoke',
                         {present,1},
                         asn1_NOVALUE,
                         {local,2},
                         MapData}}}]}},
    {ok, EncMapPDU} = map:encode('MapSpecificPDUs', MapPDU),
    EncMapPDU.
    
create_anyTimeInterrogation() ->
    create_anyTimeInterrogation(?IMSI, ?LOCAL_GLOBAL_TITLE).
create_anyTimeInterrogation(Imsi, GsmSCF) ->
    MapData = {'AnyTimeInterrogationArg',
                 {imsi, ss7_helper:encode_imsi(Imsi)}, %{msisdn,?MSISDN},
                 {'RequestedInfoMAP-MS-DataTypes',asn1_NOVALUE,
                     'NULL',asn1_NOVALUE,asn1_NOVALUE,
                     asn1_NOVALUE,asn1_NOVALUE,asn1_NOVALUE,
                     asn1_NOVALUE,asn1_NOVALUE,asn1_NOVALUE},
                 ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                        GsmSCF),     %gsmSCF-Address
                 asn1_NOVALUE},
    Dialog = build_dialog_request(?'anyTimeInfoEnquiryContext-v3'),
    encode_map_pdu(Dialog, 71, MapData).

create_sendAuthenticationInfo() ->
    create_sendAuthenticationInfo(?IMSI).
create_sendAuthenticationInfo(Imsi) ->
    create_sendAuthenticationInfo(Imsi, 5).
create_sendAuthenticationInfo(Imsi, Nr) ->
    MapData = { 'SendAuthenticationInfoArg',
                ss7_helper:encode_imsi(Imsi),
                Nr,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE,
                asn1_NOVALUE},
    MapPDU = {'begin',
        {'MapSpecificPDUs_begin',
            get_transactionId(), 
            {'EXTERNAL',
                ?'dialogue-as-id',
                asn1_NOVALUE,asn1_NOVALUE,
                {'single-ASN1-type',<<96,11,161,9,6,7,4,0,0,1,0,14,3>>}},
            [{basicROS,
                 {invoke,
                     {'MapSpecificPDUs_begin_components_SEQOF_basicROS_invoke',
                         {present,1},
                         asn1_NOVALUE,
                         {local,56},
                         MapData}}}]}},
    {ok, EncMapPDU} = map:encode('MapSpecificPDUs', MapPDU),
    EncMapPDU.

create_sendImsi() ->
    create_sendImsi(?MSISDN).
create_sendImsi(Msisdn) ->
    MapData = ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                    ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                    Msisdn),
    Dialog = build_dialog_request(?'imsiRetrievalContext-v2'),
    encode_map_pdu(Dialog, 58, MapData).

create_purgeMs() ->
    create_purgeMs(?IMSI, ?LOCAL_GLOBAL_TITLE).
create_purgeMs(Imsi, VlrNr) ->
    MapData = {'PurgeMs-Arg',
                ss7_helper:encode_imsi(Imsi),
                ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                        VlrNr),   %VLR number
                asn1_NOVALUE,   %SGSN number
                asn1_NOVALUE},  %Last Known Location
    Dialog = build_dialog_request(?'msPurgingContext-v3'),
    encode_map_pdu(Dialog, 67, MapData).

% gsm_map and tcap.localValue == 59
create_processUnstructuredSS() ->
    create_processUnstructuredSS(?IMSI, ?MSISDN, "*100#").
create_processUnstructuredSS(Imsi, Msisdn, UssdString) ->
    MapDialoguePDU = {'map-open',
                    {'MAP-OpenInfo',
                        ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                            ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_LAND_MOBILE,
                            Imsi),    %destinationReference
                        ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                            ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                            Msisdn),   %originationReference
                        asn1_NOVALUE }},
    {ok, EncMapDialoguePDU} = map:encode('MAP-DialoguePDU', MapDialoguePDU),
    DialoguePDU = {'dialogueRequest',
                    {'AARQ-apdu',
                        [version1],
                        ?'networkUnstructuredSsContext-v2',
                        [{'EXTERNAL',
                            ?'map-DialogueAS',
                            asn1_NOVALUE,asn1_NOVALUE,
                            {'single-ASN1-type',
                                EncMapDialoguePDU}}]}},
    {ok, EncDialoguePDU} = map:encode('DialoguePDU', DialoguePDU),
    MapData = {'USSD-Arg',
                <<15>>,     %ussd-DataCodingScheme; 0x0f = 15 == Coding Group 0 [gsm 7bit]; Language unspecified
                'sms_7bit_encoding':to_7bit(UssdString), %<<170,152,12,54,2>>,    %ussd-String
                asn1_NOVALUE,asn1_NOVALUE},
    encode_map_pdu(EncDialoguePDU, 59, MapData).

% gsm_map and tcap.localValue == 65
create_anyTimeModification() ->
    create_anyTimeModification(?IMSI, ?LOCAL_GLOBAL_TITLE).
create_anyTimeModification(Imsi, GsmSCF) ->
    MapData = {'AnyTimeModificationArg',
          {imsi, ss7_helper:encode_imsi(Imsi)},  %~ subscriberIdentity                  [0]  SubscriberIdentity,
          ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                        GsmSCF),                 %~ gsmSCF-Address                      [1]  ISDN-AddressString,
          asn1_NOVALUE,                          %~ modificationRequestFor-CF-Info      [2]  ModificationRequestFor-CF-Info OPTIONAL,
          asn1_NOVALUE,                          %~ modificationRequestFor-CB-Info      [3]  ModificationRequestFor-CB-Info OPTIONAL,
          asn1_NOVALUE,                          %~ modificationRequestFor-CSI          [4]  ModificationRequestFor-CSI OPTIONAL,
          asn1_NOVALUE,                          %~ extensionContainer                  [5]  ExtensionContainer OPTIONAL,
          asn1_NOVALUE,                          %~ longFTN-Supported                   [6]  NULL OPTIONAL,
          asn1_NOVALUE                           %~ modificationRequestFor-ODB-data     [7]  ModificationRequestFor-ODB-data OPTIONAL
            },
    Dialog = build_dialog_request(?'anyTimeInfoHandlingContext-v3'),
    encode_map_pdu(Dialog, 65, MapData).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% to MSC/VLR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_provideSubscriberInfo() ->
    create_provideSubscriberInfo(?IMSI).
create_provideSubscriberInfo(Imsi) ->
    MapData = {'ProvideSubscriberInfoArg',
         ss7_helper:encode_imsi(Imsi),
         asn1_NOVALUE,
         {'RequestedInfoMAP-MS-DataTypes',
            'NULL',         %locationInformation
            'NULL',   %subscriberState
            asn1_NOVALUE,   %extensionContainer
            'NULL',   %currentLocation
            asn1_NOVALUE,   %requestedDomain
            'NULL',   %imei
            asn1_NOVALUE,   %ms-classmark
            asn1_NOVALUE,   %mnpRequestedInfo
            asn1_NOVALUE,   %t-adsData
            asn1_NOVALUE    %requestedNodes
            },
        asn1_NOVALUE,
        asn1_NOVALUE},
    Dialog = build_dialog_request(?'subscriberInfoEnquiryContext-v3'),
    encode_map_pdu(Dialog, 70, MapData).

create_provideSubscriberLocation() ->
    create_provideSubscriberLocation(?IMSI, ?LOCAL_GLOBAL_TITLE).
create_provideSubscriberLocation(Imsi, Mlc) ->
    MapData = {'ProvideSubscriberLocationArg',
          {currentOrLastKnownLocation, asn1_NOVALUE},            %~ locationType            LocationType,
          ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                        ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                        Mlc),                                    %~ mlc-Number              ISDN-AddressString,
          asn1_NOVALUE,                                          %~ lcs-ClientID            [0]  LCS-ClientID OPTIONAL,
          asn1_NOVALUE,                                          %~ privacyOverride         [1]  NULL OPTIONAL,
          ss7_helper:encode_imsi(Imsi),                          %~ imsi                    [2]  IMSI OPTIONAL,
          asn1_NOVALUE,                                          %~ msisdn                  [3]  ISDN-AddressString OPTIONAL,
          asn1_NOVALUE,                                          %~ lmsi                    [4]  LMSI OPTIONAL,
          asn1_NOVALUE,                                          %~ imei                    [5]  IMEI OPTIONAL,
          asn1_NOVALUE,                                          %~ lcs-Priority            [6]  LCS-Priority OPTIONAL,
          asn1_NOVALUE,                                          %~ lcs-QoS                 [7]  LCS-QoS OPTIONAL,
          asn1_NOVALUE,                                          %~ extensionContainer      [8]  ExtensionContainer OPTIONAL,
          asn1_NOVALUE,                                          %~ supportedGADShapes      [9]  SupportedGADShapes OPTIONAL,
          asn1_NOVALUE,                                          %~ lcs-ReferenceNumber     [10]  LCS-ReferenceNumber OPTIONAL,
          asn1_NOVALUE,                                          %~ lcsServiceTypeID        [11]  LCSServiceTypeID OPTIONAL,
          asn1_NOVALUE                                           %~ lcsCodeword             [12]  LCSCodeword OPTIONAL
          },
    Dialog = build_dialog_request(?'locationInfoRetrievalContext-v3'),
    encode_map_pdu(Dialog, 83, MapData).

create_sendIdentification() ->
    create_sendIdentification(?TMSI).
create_sendIdentification(Tmsi) ->
    MapData = { 'SendIdentificationArg',
            Tmsi,
            5,              %NumberOfRequestedVectors
            asn1_NOVALUE,   %segmentationProhibited
            asn1_NOVALUE,   %ExtensionContainer
            asn1_NOVALUE,   %msc-Number
            asn1_NOVALUE,   %previous-LAI
            asn1_NOVALUE    %hopCounter
            },
    Dialog = build_dialog_request(?'interVlrInfoRetrievalContext-v3'),
    encode_map_pdu(Dialog, 55, MapData).

create_provideRoamingNumber() ->
    create_provideRoamingNumber(?IMSI, ?MSISDN, ?LOCAL_GLOBAL_TITLE, ?LOCAL_GLOBAL_TITLE).
create_provideRoamingNumber(Imsi, Msisdn, MscNr, GmscNr) ->
    MapData = {'ProvideRoamingNumberArg',
                 ss7_helper:encode_imsi(Imsi),
                 ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                            ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                            MscNr),         %msc-Number
                 ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                    ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                    Msisdn),
                 asn1_NOVALUE,
                 {'ExternalSignalInfo','gsm-0408',
                     <<4,1,160>>,
                     asn1_NOVALUE},
                 asn1_NOVALUE,asn1_NOVALUE,
                 ss7_helper:encode_msisdn(?NUMBER_EXTENSION_NONE,
                            ?NUMBER_NATURE_INTERNATIONAL, ?NUMBER_PLAN_ISDN,
                            GmscNr),          %gmsc-Address
                 <<112,4,1,54,22,114,55>>,          %callReferenceNumber
                 asn1_NOVALUE,asn1_NOVALUE,asn1_NOVALUE,
                 asn1_NOVALUE,
                 [phase1,phase2,phase3],
                 asn1_NOVALUE,'NULL',asn1_NOVALUE,asn1_NOVALUE,
                 asn1_NOVALUE,asn1_NOVALUE,asn1_NOVALUE,
                 asn1_NOVALUE,asn1_NOVALUE},
    Dialog = build_dialog_request(?'roamingNumberEnquiryContext-v3'),
    encode_map_pdu(Dialog, 4, MapData).

create_cancelLocation() ->
    create_cancelLocation(?IMSI).
create_cancelLocation(Imsi) ->
    MapData = {'CancelLocationArg',
                 {imsi, ss7_helper:encode_imsi(Imsi)},
                 updateProcedure,
                 asn1_NOVALUE,
                 asn1_NOVALUE},
    Dialog = build_dialog_request(?'locationCancellationContext-v3'),   %v2: {0,4,0,0,1,0,2,2}
    encode_map_pdu(Dialog, 3, MapData).

create_insertSubscriberData() ->
    MapData = {'InsertSubscriberDataArg',
        asn1_NOVALUE,   %imsi
        asn1_NOVALUE,   %msisdn
        asn1_NOVALUE,   %additional msisdn
        asn1_NOVALUE,   %category
        asn1_NOVALUE,   %subscriber status
        asn1_NOVALUE,   %bearer service list
        asn1_NOVALUE,   %teleservice list
        asn1_NOVALUE,   %forwarding information list
        asn1_NOVALUE,   %call barring information list
        asn1_NOVALUE,   %CUG information list
        asn1_NOVALUE,   %SS-Data list
        asn1_NOVALUE,   %eMLPP subscription data
        asn1_NOVALUE,   %MC-subscription data
        asn1_NOVALUE,   %
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE,
        asn1_NOVALUE
        },
    Dialog = build_dialog_request('subscriberDataMngtContext-v3'),
    encode_map_pdu(Dialog, 7, MapData).
