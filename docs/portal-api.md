# MyLA311 Portal API

> **File:** `docs/portal-api.md`

Agent-facing endpoint reference for the MyLA311 Portal
(`https://myla311.lacity.gov`), covering the guest **Illegal Dumping Item Pickup**
contract and the captured **Barricade Removal** journey through final review.
Built from real browser traffic
(Playwright MCP, 2026-10-21) plus the Portal's own JavaScript, followed by
read-only HTTP replays and one separately recorded helper submission.

## Status at a glance

- The discovery read calls below worked from a plain HTTP client: no browser, no
  cookies, no CSRF token, no CAPTCHA, no bot check (replayed, HTTP 200).
- Discovery stopped before `submitCase`. Its contract is source-derived.
  A later host-side Flutter test invoked the production client and recorded
  accepted result **C-04955177**. The original successful response envelope
  was not retained. A 6 November read verified that City record as **Closed**.
  Native UI submission and the original successful response remain unverified;
  no further submission is authorized.
- There is no separate photo-upload endpoint. Photos travel inside the
  submit call as base64.

Labels used per endpoint:

- **captured**: seen in real browser traffic.
- **replayed**: re-sent read-only from a plain HTTP client, HTTP 200.
- **from source**: contract derived from the Portal's JavaScript.
- **helper result**: a local execution record, distinct from raw City traffic
  and native UI evidence.

## Reusable workspace and current attachment evidence (2026-10-22)

Import the [read-only Postman collection](api-workspace/myla311-read-only.postman_collection.json)
and follow its [workspace guide](api-workspace/README.md). It bootstraps fresh
guest context and chains discovery, questions, coordinate validation, and
duplicate inspection. Dispatch is absent from the executable collection.
Separate [inert contract examples](api-workspace/contract-examples.json) show
source-derived submit/result shapes with explicitly synthetic values.

Fresh read-only HTTP inspection returned 200 for `GET /s/`,
`fetchInitialDetails`, `fetchCaseTypeDetails`, `validateAddress`, and
`getRelatedCaseLst`. The current illegal-dumping configuration advertises
`sImageCount:5`, `sUploadRequired:false`, `sDisplayUpload:true`, and
`sImageFormats:".heic;.heif;.jpeg;.jpg;.pdf;.png;.webp"`. The retained Portal
source maps every ordered attachment to the submit array; this establishes the
advertised/source-supported contract for up to three native photos. It is not
a captured three-photo acceptance, and the server aggregate request-size limit
remains unknown. No City write was performed.

[Attachment provenance](api-workspace/attachment-contract.json) records current
response/source hashes and exact source excerpts, including byte limits,
filename normalization, image encoding, and array ordering. The workspace guide
distinguishes observed/minimized responses from synthetic examples. The original
successful transaction and native-send evidence gaps remain unresolved.

### Native Dev/API inspector

The Home and Help `Dev / API` utility opens a native sheet with a fixed header
and footer. It exposes named illegal-dumping operations on the fixed MyLA311
guest/Aura routes, not arbitrary method, URL, header, or body controls. Opening
the sheet, selecting an operation, and previewing its arguments do not send a
request; a read runs only after **Run 311 request**. The optional
`getRelatedCaseLst` read is separate from the normal `PortalSubmissionClient`
flow.

Report values seed the inspector snapshot and submit preview, but inspector edits
do not modify the saved Report or draft. A `submitCase` write requires review of
the exact destination and payload, followed by explicit confirmation. A confirmed
Service Request and its saved duplicate lock persist across sessions. An existing
unconfirmed or uncertain attempt remains blocked; the operator can check MyLA311
or call 3-1-1, but no automatic retry or inspector override unlock is promised.
Cancel aborts locally and cannot prove the City did not receive a write. The
60-second timeout reports no response, and the inspector does not retry
automatically. Its latest 12 history summaries stay in memory and omit bodies
and session values. No live City write or acceptance was verified for this
inspector.

## Barricade Removal: captured guest contract, 5 November 2026

The City browser journey reached **Review & Submit** with anonymous contact,
the location choice **Street**, no attachments, and the verified public address
**200 N MAIN ST, LOS ANGELES, CA 90012**. The **Submit** button was not pressed.
This verifies discovery, questions, address validation and similar-request reads.
The app now has a native Barricade client/UI candidate using this contract.
Barricade dispatch, server acceptance and native completion remain unverified;
no live send is authorized.

The retained sanitized HAR, `barricade-review.har`, contains ten Apex exchanges.
Its SHA-256 is
`edde5b34c874b33f820f55c4aeb00cb77f38c5df90b977d01c9a6de8cb2f2420`.
Every recorded exchange returned HTTP 200 with Aura action state `SUCCESS`;
there is no `submitCase` exchange in the capture. The HAR stays in local evidence,
outside the published source tree.

### Discovery and call order

Use the common Aura transport below, with a current guest bootstrap.

1. `X11_H_ParentController.fetchInitialDetails`: select the entry whose
   `uxType` is `Barricade Removal` and `uxGroup` is `Street Problems/Repairs`.
   Read its current `caseConfigId`; encrypted identifiers are session-specific.
2. `X11_RI_ParentController.fetchCaseTypeDetails`: send
   `{"caseTypeId":"<current decoded catalog ID>","parentWorkOrderId":"","isSNC":false}`.
   The captured page URI was `/s/report-issue?c__IssueTypeId=<encoded ID>&c__IsPortalUser=true`.
   Its successful response contains `objCaseConfigWrapper` and
   `contactWrapperResponse`.
3. `LA_AddressController.validateOriginalAddress`: send
   `{"address":"200 N Main St, Los Angeles, CA 90012"}`. Read the returned
   address and validation result, rather than substituting an illustrative pin.
4. `X11_RI_ParentController.getRelatedCaseLst`: the browser sent
   `{"caseType":"Barricade Removal","caseLatitude":34.053264,"caseLongitude":-118.242189}`.
   It then advanced to final review. These are the captured coordinates;
   implementations must use the resident's validated location.

The similar-request response carried `isSuccess:false` with
`message:"No Data Available"`. The browser continued to final review; the
capture establishes an empty result, not returned matching requests.

The browser called `fetchCaseTypeDetails` twice with identical parameters.
That duplication is observed browser behavior, not a requirement to duplicate
the native request. The contact selector offered anonymous **Yes** and **No**;
only the anonymous path was exercised in this capture.

### Questions and validation

Read `sQuestion`, `sQuestionType`, `sFieldtoUpdate`, `brequired`, `lstOptions`,
`sAnswer`, visibility and validation metadata from the fresh configuration.
There are three configured questions and no preliminary questions.

| City field | Question and accepted values | Required |
| --- | --- | --- |
| `Problem_Type__c` | Select the location of the Barricade Removal: `Alley`, `Sidewalk`, `Street` | Yes |
| `Description` | Additional Comments, up to 750 characters | No |
| `ADA_Question__c` | Disability-access question: `Decline to Answer`, `No`, `Yes`; empty is permitted | No |

Captured question IDs, in that order, were `a3Teq0000003J5XEAU`,
`a3Teq0000003J4nEAE` and `a3Teq0000003J5kEAE`. Match the current configuration;
do not treat these captured IDs as permanent. An unanswered optional question
must remain unanswered. In particular, do not invent a disability answer.

The configuration identifies `sCaseType: Barricade Removal`,
`sCaseCategory: Street Problems/Repairs`, `sCasePriority: Normal` and
`sCaseDefaultStatus: New`. It allows anonymous reporting and requires a map
location within `City Boundary`; `locatorRequired` is false.

### Evidence and submission boundary

Uploads are optional. The configuration advertises five files and
`.heic;.heif;.jpeg;.jpg;.pdf;.png;.webp`. The browser additionally displays a
10 MB maximum per image and at most one PDF of 3 MB. No file upload or aggregate
payload limit was exercised. The existing dumping client's three-photo limit
does not establish Barricade's upload support.

The shared `submitCase` envelope below is source-derived. A Barricade payload
must carry Barricade's own configuration, answers and validated address;
the existing dumping answer builder cannot be reused unchanged. No captured
Barricade submit payload or accepted Service Request response is available yet.

### Current shared submit preparation (source recovered 6 November 2026)

The public Aura module loader returned HTTP 200 with 1,069,816 bytes, retained at
`.scratch/portal-mobile-parity/evidence/barricade-contract-20261105/portal-modules-20261106.js`.
SHA-256: `2eef1b3ab43820f6fee390aad2f6b2d29de6cdbac9725d5254191ca687faba5b`.
To locate the current loader, discover the `bootstrap.js` script URL from
`GET https://myla311.lacity.gov/s/`, then read `pageLoaderCmpDefBaseUri`
from that script's configuration. Use the
component-definition GET with `_def=markup://c:laCaseCreationFlow`; do not
assume the bootstrap script lives at `/s/bootstrap.js` (that URL returned
HTTP 404 on 6 November 2026). The response's `initModuleDefs` JSON
contains `co` source strings for `c/laRiDetails` and `c/laCaseCreationFlow`.
This is Portal source evidence, not a captured submit request.

For the captured non-SNC Barricade journey, these shared functions prepare the
request in this order:

1. `c/laRiDetails.handleContinue()` reads each question control's value into
   `sAnswer`, validates questions, uploads and the map, and builds the Case from
   the current configuration's origin, priority, status, web visibility and
   service type. Location starts with map values; a successful locator overrides
   the street, city, postal code and coordinates. It carries locator status and
   the Google-formatted boundary address. It sorts a copy of `lstCaseQuestion`
   ascending by `(iOrder || 0)` before passing details and map provenance to the
   parent flow.
2. `c/laCaseCreationFlow.submitRequest()` adds client, session and address-entry
   metadata and sets `Origin: "Self Service"` for Portal users. It removes
   `dwpContainerLst`, filters questions whose `sFieldtoUpdate` is `null` or
   `undefined`, then floors only numeric, non-integer `iOrder` values. It does
   not sort again after flooring.
3. It copies `contactWrapperResponse` and merges non-null, non-undefined,
   non-empty `sFirstName`, `sLastName`, `sEmail`, `sPhone`, `sExtension` and
   `isAnonymously` values. Explicit `isAnonymously: false` is preserved;
   an undefined anonymity value defaults to `false`.
4. It calls `X11_RI_ParentController.submitCase` with the endpoint 6 wrapper:
   `sObjCase` is an object; `sObjContact`, `sCaseQuestionJSON` and `sFileLinks`
   are JSON text; `isSNC` is `false`. Each ordered attachment retains its
   metadata while `fileData` becomes the portion after `base64,`.
   `addressDetails` is JSON text of `locatorResponse.locatorDetails` only when
   that object is present.

These source functions establish the shared preparation contract. They do not
verify Barricade dispatch, City acceptance or native completion. No City write
was performed during this source recovery.

## Platform

The Portal is a Salesforce Experience Cloud (Aura/LWC) site. There is no
REST or GraphQL API. Every data call is an **Aura Apex action**: one POST
endpoint, with the Apex class and method named inside a form field. Guests
need no login. The page that the browser shows is `/s/report-issue`, a
five-step wizard: Request Type, Contact Details, Request Details, Review
Similar Request, Review and Submit.

## Call order (happy path)

1. `GET /s/`: guest bootstrap (optional but recommended). [captured,
   replayed]
2. `X11_H_ParentController.fetchInitialDetails`: list of request types;
   take the `caseConfigId` of "Illegal Dumping Item Pickup". [captured,
   replayed]
3. `X11_RI_ParentController.fetchCaseTypeDetails`: question config and
   default contact object for that type. [captured, replayed]
4. Location lookup, one of:
   - `LA_AddressController.validateAddress` (latitude and longitude).
     [from source, replayed]
   - `LA_AddressController.validateOriginalAddress` (address text).
     [captured, replayed]
5. `X11_RI_ParentController.getRelatedCaseLst`: duplicate check.
   [captured, replayed]
6. `X11_RI_ParentController.submitCase`: creates the Service Request.
   [from source; later helper result, raw successful envelope unavailable]

Calls 2 to 5 carry no state from one to the next except the values noted
under each endpoint. Photos are only read client-side (step 3 of the
wizard) and sent in call 6.

## Transport: Aura Apex action (all Apex calls)

Common to endpoints 2 to 6.

- Method and URL: `POST https://myla311.lacity.gov/s/sfsites/aura`
  with query `?r=<n>&aura.ApexAction.execute=1`. `r` is a per-page request
  counter (browser starts at 0 and increments). Replays used 1, 2, 3 and
  so on.
- Required header: `Content-Type: application/x-www-form-urlencoded;
  charset=UTF-8`. Nothing else was needed (replayed with only a
  `User-Agent` and `Accept`). The browser also sends `Origin`, `Referer`,
  `x-sfdc-*` and `x-b3-*` headers; none are required.
- Body: four form fields, URL-encoded.

| Field | Value |
| --- | --- |
| `message` | JSON, see below |
| `aura.context` | JSON, see below |
| `aura.pageURI` | `/s/` or the `/s/report-issue?...` path |
| `aura.token` | the literal text `null` (guest) |

`message` (decoded):

```json
{"actions":[{"id":"1;a",
 "descriptor":"aura://ApexActionController/ACTION$execute",
 "callingDescriptor":"UNKNOWN",
 "params":{"namespace":"","classname":"<ApexClass>",
  "method":"<apexMethod>","params":{ "<name>": "<value>" },
  "cacheable":false,"isContinuation":false}}]}
```

`aura.context` (decoded; `fwuid` and the app id come from `GET /s/`):

```json
{"mode":"PROD","fwuid":"<FWUID>","app":"siteforce:communityApp",
 "loaded":{"APPLICATION@markup://siteforce:communityApp":"<APP_ID>"},
 "dn":[],"globals":{},"uad":true}
```

Response (HTTP 200 even for application errors):

```json
{"actions":[{"id":"1;a","state":"SUCCESS",
  "returnValue":{"returnValue":"<JSON TEXT>","cacheable":false},
  "error":[]}],
 "context":{"...":"ignore"}}
```

`returnValue.returnValue` is a **JSON string** that must be parsed again.
It is the Portal envelope:

```json
{"toastPayload":null,"response":<payload>,"message":"<text>",
 "isSuccess":true,"isHTML":null,"errorLogs":null,"ccbCheck":null}
```

`response` is an object for some methods and a second JSON string for
others (noted per endpoint). `isSuccess:false` plus `message` is the
Portal's own error. A non-`SUCCESS` `state` is an Aura error (never seen
in the happy path).

## Endpoint 1: guest bootstrap

- Purpose: mint the guest session values and read the Aura context.
- Label: captured, replayed.
- Request: `GET https://myla311.lacity.gov/s/`, `Accept: text/html`. No
  special headers (replayed with a custom `User-Agent`).
- Response: HTTP 200, `text/html`, about 120 KB. The page is a shell, but
  the HTML contains the Aura context.
- Where each value comes from (URL-decode the HTML first, then match):
  - `fwuid`: regex `"fwuid":"([^"]+)"`. Example `<base64 text, about
    70 chars>` (a framework version id that changes with Salesforce
    releases).
  - `APP_ID`: regex
    `"loaded":\{"APPLICATION@markup://siteforce:communityApp":"([^"]+)"`.
    Example `1893_<22 chars>`.
- Cookies set (all optional, see verdict): `CookieConsentPolicy`,
  `LSKey-c$CookieConsentPolicy`, `renderCtx`. Values redacted.
- Capture ids: browser `003`; plain HTTP `H01` (see Captures index).

## Endpoint 2: request types

- Purpose: read the current service catalog and find a selected request type's
  session-specific id.
- Label: captured, replayed.
- Apex: `X11_H_ParentController.fetchInitialDetails`
- `params`: none. `cacheable`: `true`. `aura.pageURI`: `/s/`.
- `response` (object): `popularCaseList[]`, `isPortalUser`,
  `caseConfigurationList[]` (groups with `uxGroup` and `caseConfigurations[]`). The
  Illegal Dumping tile is in `popularCaseList` and again in
  `caseConfigurationList`.
- Pick the entry whose `uxType` is `Illegal Dumping Item Pickup`.
- Native catalog discovery uses each grouped entry's `uxType` and its group's
  `uxGroup`. A read-only replay on 2026-10-29 returned 14 groups. The native
  list reads fresh names and groups without storing `caseConfigId`; other
  service journeys remain explicitly local previews until their separate
  City integrations are verified.

Redacted example (one entry):

```json
{"uxType":"Illegal Dumping Item Pickup",
 "uxGroup":"Refuse & Collection Services",
 "uxDescription":"Illegal Dumping refers to high volume ...",
 "pSequence":2,"iconName":"truck-ramp-couch-light",
 "casePopularType":true,"caseEstimation":"0",
 "caseConfigId":"<ENCRYPTED_ID, percent-encoded>"}
```

- `caseConfigId` is an opaque encrypted string (about 64 chars,
  percent-encoded, containing `%2F` and `%2B`). It **differs on every
  call** (random IV) and any fresh value was accepted by endpoint 3, so
  do not cache or hard-code it. The browser puts it in the page URL as
  `c__IssueTypeId` and then URL-decodes it before use.
- Capture ids: browser `011`; plain HTTP `H02`.

## Endpoint 3: case type details (the question form)

- Purpose: the server-driven form: every question, its type, options and
  parent/answer dependency, plus the default contact object.
- Label: captured (response truncated at 300000 chars in the browser
  capture), replayed in full (329 KB).
- Apex: `X11_RI_ParentController.fetchCaseTypeDetails`
- `aura.pageURI`:
  `/s/report-issue?c__IssueTypeId=<percent-encoded id>&c__IsPortalUser=true`
- `params`:

```json
{"caseTypeId":"<caseConfigId, URL-DECODED (raw / and +)>",
 "parentWorkOrderId":"","isSNC":false}
```

- `cacheable`: `false`.
- `response` (object) keys: `scaseTypeLst` (all request type names),
  `objCaseConfigWrapper`, `mapLabels`, `inStages`, `allStages`,
  `contactWrapperResponse`.
- `objCaseConfigWrapper` (important keys): `sId`, `sCaseType`
  (`Illegal Dumping Item Pickup`), `sCasePriority` (`Normal`),
  `sCaseDefaultStatus` (`New`), `sCaseCategory`, `sBoundary`
  (`City Boundary`), `sReportAnonymously` (`true`), `sUploadRequired`
  (`false`), `sImageCount` (`5`), `sImageFormats`
  (`.heic;.heif;.jpeg;.jpg;.pdf;.png;.webp`), `locatorRequired`
  (`false`), `sMapOptional` (`false`), `lstCaseQuestion[]` (210 items),
  `lstBeforeCaseQuestion[]` (empty), `dwpContainerLst` (`null`).
- Each `lstCaseQuestion` item (30 keys). The ones that matter:
  `sFieldtoUpdate` (the target field name and the answer key),
  `sQuestion` (label), `sQuestionType` (`Picklist`, `MultiPicklist`,
  `Text`, `TextArea`, `Phone`, `NumberIncrement`), `brequired`,
  `sDisplay` (visible now), `sHidden`, `sReadOnly`, `sDefaultValue`,
  `sAnswer` (the value the client fills in), `lstOptions[]`
  (`{value,label}`), `iOrder`, `sQuestionConfigId`,
  `sQuestionParentConfigId`, `sParentQuestion`, `sParentAnswer`
  (`;`-separated list of parent answers that make this question appear),
  `lstValidations[]` (`maximumLimit`, `minimumLimit`, `required`).
- `contactWrapperResponse`: the default contact object (all null except
  `sUserName` = the guest user, `bIsLogin:false`, `isAnonymously:null`).

Redacted question example:

```json
{"sQuestionType":"Picklist","sFieldtoUpdate":
 "Provide_Information_On_Suspect__c","brequired":true,"sDisplay":true,
 "sQuestion":"Will you be able to provide information on the Illegal
  Dumping suspect?","lstOptions":[{"value":"","label":"Select any one
  picklist option"},{"value":"No","label":"No"},{"value":"Yes",
  "label":"Yes"}],"iOrder":4,"sAnswer":null,
 "sQuestionConfigId":"a3Req0000004VbdEAE","sParentAnswer":""}
```

- The form is data-driven: answering a question can make child
  questions visible (their `sParentQuestion`/`sParentAnswer` match). See
  "Questions for the happy path" below.
- Capture ids: browser `038` and `039` (both truncated); plain HTTP
  `H03` (full response).

## Endpoint 4a: location by coordinates

- Purpose: resolve a latitude and longitude to a City-verified address
  and its service districts. This is the Portal's pin-drop path.
- Label: from source (laGoogleMap component), replayed with HTTP 200. The
  browser walk used 4b instead.
- Apex: `LA_AddressController.validateAddress`
- `params`:

```json
{"latitude":34.054047,"longitude":-118.24317,
 "addressType":"City Boundary","filterCriteria":""}
```

- `cacheable`: `false`. `aura.pageURI`: any `/s/...` path.
- `response`: a **JSON string** `{"address":{...78 attributes},"location":
  {"x":<lng>,"y":<lat>,"z":0,"spatialReference":{...}}}`. Envelope
  `message` is `Locator Success` and `isSuccess` is `true`.
- `address` keys used by the submit call: `ShortLabel`, `LongLabel`,
  `City`, `Postal`, `X`, `Y`, `Addr_type`. The other attributes are
  district data (council district, sanitation, police, and so on) and
  are forwarded unchanged inside `addressDetails`.
- Failure: `isSuccess:false`, `message` is `Locator Address Invalid`
  (the point is outside the City or has no address) or `Locator Is-Down`.
- The browser then uses `address` as `locatorDetails`, with
  `locatorStatus` set to the envelope `message`.
- Capture id: plain HTTP `H04`. The test point returned a residential
  street address, not reproduced here.

## Endpoint 4b: location by address text

- Purpose: validate a typed or Google-geocoded address against the City
  locator (this is what the Portal's search box and device-location path
  call).
- Label: captured, replayed.
- Apex: `LA_AddressController.validateOriginalAddress`
- `params`: `{"address":"200 N Spring St, Los Angeles, CA 90012"}`
- `response`: a **JSON string** in ArcGIS locator format:
  `{"spatialReference":{...},"candidates":[{"address","location":{"x",
  "y","z"},"score","attributes":{...},"extent":{...}}]}`. The Portal uses
  `candidates[0].attributes` as `locatorDetails`.
- Failure example (captured): `isSuccess:false`, `message` =
  `Locator Address Invalid`, `response` = `Unable to find address for
  the specified location.`
- Redacted success (City Hall, a public address), attributes trimmed:

```json
{"address":"200 N SPRING ST, LOS ANGELES, CA, 90012",
 "location":{"x":-118.24317,"y":34.054047,"z":0.0},"score":100,
 "attributes":{"Status":"M","Score":100,"Addr_type":"PointAddress",
  "LongLabel":"200 N SPRING ST, LOS ANGELES, CA, 90012",
  "ShortLabel":"200 N SPRING ST","AddNum":"200","StName":"SPRING",
  "City":"LOS ANGELES","Postal":"90012","X":-118.24317,"Y":34.054047,
  "SRCouncilDistrictNo":14,"In_City":"YES","...":"~70 more fields"}}
```

- Capture ids: browser `099` (success), `081` (invalid address), `082`
  (coordinates typed as text, success); plain HTTP `H05`.
- Not needed by a native app: the Google Maps JS in the iframe
  (`/GoogleMapPage`, Places Autocomplete and Geocoder, with the Portal's
  own browser key) only turns what the user types into an address string
  and a Google-formatted address. The app has its own coordinates and can
  call 4a directly.

## Endpoint 5: duplicate check

- Purpose: find existing open requests of the same type near the point
  (the "Review Similar Request" step).
- Label: captured, replayed.
- Apex: `X11_RI_ParentController.getRelatedCaseLst`
- `params`:
  `{"caseType":"Illegal Dumping Item Pickup","caseLatitude":34.054047,
  "caseLongitude":-118.24317}` (the `X`/`Y` of the locator result).
- Response when nothing is nearby (captured): `response:null`,
  `message:"No Data Available"`, `isSuccess:false`. The browser then
  skips to Review. The shape when duplicates exist was not seen.
- Capture ids: browser `106`; plain HTTP `H06`.

## Endpoint 6: submit (creates the Service Request)

- Purpose: create the Case and attach photos in one call.
- Label: **from source; later helper result recorded**. No browser submit
  capture or original successful response envelope was recovered. Source:
  LWC `c/laCaseCreationFlow.submitRequest()`, Apex
  import `@salesforce/apex/X11_RI_ParentController.submitCase`.
- Apex: `X11_RI_ParentController.submitCase`. `cacheable`: `false`.
  `aura.pageURI`:
  `/s/report-issue?c__IssueTypeId=<id>&c__IsPortalUser=true`.
- `params` (names exact; types as the Portal sends them):

```json
{"sObjCase":{ "...Case fields, see below..." },
 "sObjContact":"<JSON TEXT>",
 "sCaseQuestionJSON":"<JSON TEXT>",
 "sFileLinks":"<JSON TEXT>",
 "isSNC":false,
 "addressDetails":"<JSON TEXT>"}
```

`sObjCase` is an **object** (not a string) with these fields:

- `Type`: `objCaseConfigWrapper.sCaseType`
  (`Illegal Dumping Item Pickup`).
- `Priority`: `Normal`. `Status`: `New`. (From `sCasePriority` and
  `sCaseDefaultStatus`.) `Hide_from_Web__c`: `sHideFromWeb` (null).
- `Origin`: `Self Service` (set for portal users).
- `Created_From_SNC__c`: `No`. `Tech_SNC_CaseNumber__c`: `""`.
- Location, from the locator result (`locatorDetails`):
  `Street_Address__c` = `ShortLabel`, `City__c` = `City`,
  `Zipcode__c` = `Postal`, `Geolocation__Longitude__s` = `X`,
  `Geolocation__Latitude__s` = `Y`, `State__c` = `CA`,
  `Country__c` = `US`.
- `Address_Status__c`: `locatorResponse.locatorStatus`, falling back to the
  Portal's `LOCATORISDOWN` constant when absent.
- `Google_Address__c`: for `City Boundary` the Google-formatted address
  string from the map. The app has no Google address; whether the server
  requires it is unknown (see Unknowns).
- `Address_Entry_Method__c`: one of `Device Location`, `Manual Entry`,
  `Autocomplete Suggestion`, `Map Pin`, `Unknown` (set by the map
  iframe).
- `Session_Tracking_ID__c`: a client-made UUID (the Portal keeps it in
  `sessionStorage` under `MyLA311_Portal_Session_ID`).
- Client info (free text; Portal fills them from the browser):
  `Browser_Info__c` (`"<browser> <version>"`), `Platform_Info__c`,
  `Device_Info__c` (`Desktop`, `Mobile` or `Tablet`),
  `Application_Info__c`, `Access_Source__c` (full user agent),
  `CCB_SA_Types__c` (`""` for this type).

`sObjContact` is `JSON.stringify` of the contact object:
`contactWrapperResponse` from endpoint 3, merged with the selected contact
values as described above. `isAnonymously` is `true` for an anonymous request;
explicit `false` is preserved for a named request. Example:

```json
{"sUserName":"<guest user>","sSuite":null,"sStreet":null,"sState":null,
 "sPostalCode":null,"sPhone":null,"sOrganization":null,"sLastName":null,
 "sFirstName":null,"sExtension":null,"sEmail":null,"sCountry":null,
 "sContactId":null,"sCity":null,"sAddress":"","lstValidations":[],
 "isAnonymously":true,"bIsLogin":false}
```

`sCaseQuestionJSON` is `JSON.stringify` of `objCaseConfigWrapper` from
endpoint 3 **without `dwpContainerLst`**. The details component first fills
`sAnswer` (and maintains `sDisplay`) and sorts questions ascending by
`(iOrder || 0)`. The parent submit function then keeps only items whose
`sFieldtoUpdate` is neither null nor undefined and floors numeric, non-integer
`iOrder` values, without re-sorting. Unanswered questions with field mappings
remain in the array; the earlier dumping configuration contained 210 questions,
which is not a fixed count for Barricade or future configurations.

`sFileLinks` is `JSON.stringify` of an array, one object per photo:

```json
[{"fileData":"<BASE64, no data: prefix>","fileName":"photo.jpg",
  "showImage":true,"showPdf":false,"fileType":"jpg",
  "position":{"lat":34.054047,"lng":-118.24317},"dateTime":"<EXIF date>"}]
```

`position` is `null` when the image has no EXIF GPS; `dateTime` is only
present when EXIF has it. `[]` means no photos.

`addressDetails` is included only when `locatorResponse.locatorDetails` is
present, as `JSON.stringify(locatorDetails)`: the `address` object (4a) or
`candidates[0].attributes` (4b).

Response (from source): `returnValue.returnValue` parses to the envelope:

```json
{"isSuccess":true,"message":"...",
 "response":{"sCaseNumber":"<SR NUMBER>","sCaseId":"<RECORD ID>",
  "sAppointmentDates":"<JSON TEXT or empty>"}}
```

- **The Service Request number is `response.sCaseNumber`.** The Portal
  treats the call as failed unless `isSuccess` is true **and**
  `response.sCaseNumber` is present; it then shows `message` (or "No error
  details returned") as "Submission failed".
- `sAppointmentDates` is a JSON text array of `{serviceDate,
  workOrderNumber, workType}` (can be empty).

## Photo upload

- There is **no upload endpoint**. Selecting a file in the browser made
  no network call; the file is read in the page (`FileReader`, canvas) and
  held in memory until submit (verified in the walk: only a `blob:` URL
  request, no POST).
- Limits (from source and the `fetchCaseTypeDetails` config):
  - Up to 5 files (`sImageCount`), at most 1 of them a PDF.
  - Extensions: `.jpg .jpeg .png .heic .heif .webp` and `.pdf`.
  - Image up to 10 MB (10,000,000 bytes); PDF up to 3 MB (3,000,000);
    file name at most 60 characters.
  - Encoding the Portal applies: images are redrawn to a canvas and
    re-encoded as JPEG quality 0.5 (`image/jpeg`); if the original is over
    500,000 bytes the longest side is scaled down to 600 px. HEIC/HEIF is
    converted to JPEG in the browser. The base64 payload has the
    `data:...;base64,` prefix removed. `fileType` keeps the original
    extension. PDFs are sent as base64 unchanged.
- Photos are optional for this request type: `sUploadRequired` is `false`
  and no question carries an `imageUpload` validation.
- A client-side image-recognition POST (`AWS_Image_Recognition_URL`) exists
  in the source but was not triggered and is not part of the happy path.

## Questions for the happy path

Fill `sAnswer` on the matching `lstCaseQuestion` item (and set its
`sDisplay` to `true`, as the browser does). Answers used in the walk
(shown on the Review page), as `sFieldtoUpdate` = answer:

- `Residential_Commercial__c` = `Residential` (hidden read-only default,
  already in `sAnswer`).
- `Provide_Information_On_Suspect__c` = `No` (required).
- `Illegally_Dumped_Item_Type__c` = `I'm not sure` (required).
- `Illegally_Dumped_Pickup_Options__c` = `Loose/Miscellaneous Debris`
  (required multi-select; several values are `;`-joined).
- `Location_of_Loose_Miscellaneous_Debris__c` = `Curb` (required, one per
  selected item).
- `No_of_Loose_Miscellaneous_Debris__c` = `1` (required, min 1, max 999).
- `Description` = free text (optional, "Additional Comments", limit 750).
- `ADA_Question__c` = `Decline to Answer` (optional).

Rules found in the config:

- `Provide_Information_On_Suspect__c` = `Yes` reveals required
  `Owner_Phone_Number__c` (a phone number) and optional suspect, vehicle
  and plate fields. Answer `No` to avoid collecting a phone number.
- `Illegally_Dumped_Item_Type__c` options: `Bulky Items`,
  `Electronic Waste`, `Metal/Household Appliances`, `I'm not sure`. Each
  option reveals a required multi-select of item names; every selected
  item then reveals a required `Location_of_<Item>__c` picklist and a
  required `No_of_<Item>__c` number. `I'm not sure` offers 20 generic
  items (Auto Parts, Brush, Clothes, Loose/Miscellaneous Debris, Tires,
  Trash Bags, Wood, and others).
- Location picklist options (same for all items): `Alley`,
  `Center Median`, `Cul-de-Sac`, `Curb`, `Dead End`,
  `Easement/Pedestrian Walk`, `On Bridge`, `Side Street`, `Stairway`,
  `Under Bridge`, `Under Freeway`.
- The two gated-community and mobile-home questions (`Problem_Details_
  Sub_Type__c`, `Marking__c`) appear only for a parent answer that this
  flow never produced; leave them empty.

A read-only inspection on 2026-10-28 confirmed 95 selectable items. The
native catalog in `reports/assets/illegal_dumping_items.json` retains each
item's exact location and quantity field names. Do not derive these names
from labels: for example, `Bed Frame (Wood)` uses
`No_of_Bedframe_Wood__c`.

| Item family | Selection field | Items |
| --- | --- | --- |
| Bulky Items | `Illegally_Dumped_Other_Item_Options__c` | 40 |
| Electronic Waste | `Electronic_Waste_Options__c` | 7 |
| Metal/Household Appliances | `Metal_Household_Appliances_Options__c` | 28 |
| I'm not sure | `Illegally_Dumped_Pickup_Options__c` | 20 |

For newly selected items, the native client checks the current question types,
options and parent chain before sending. `sParentQuestionId` points to the
parent's `sQuestionId`, not `sQuestionConfigId`. Answers bind to the verified
question IDs so repeated field names on inactive branches stay unanswered.
Older drafts without item metadata retain their original debris/count mapping.

This inspection called only `GET /s/`, `fetchInitialDetails` and
`fetchCaseTypeDetails`. It did not submit a request or resolve the historical
acceptance-evidence gap.

## Required fields (what the Portal enforces)

- Contact step: **Request Anonymously** must be chosen (`Yes` or `No`).
  - `Yes`: no name, email or phone is needed (`isAnonymously:true`).
  - `No`: first name, last name and email become required; phone is
    optional (source: `contactName:true, contactEmail:true,
    contactPhone:false`).
- Location: a locator-verified address inside the City (`isSuccess:true`).
- Questions: the required ones in the table above, plus any child
  questions revealed by the chosen answers.
- Photo: not required.

## Callable outside a browser: verdict

**Discovery reads replayed successfully; one production-client helper send
reported acceptance. Native UI delivery is unverified.** Read evidence (plain
Python `urllib`, honest `User-Agent`, no browser, 2026-10-21):

- `GET /s/` returned HTTP 200 with the Aura context (capture `H01`).
- Endpoints 2, 3, 4a, 4b and 5 returned HTTP 200 and the same JSON the
  browser got (captures `H02` to `H06`).
- **No cookies needed**: the same call with every cookie dropped returned
  200 and the full payload (capture `H07`).
- **No CSRF token**: `aura.token` is the text `null` for a guest.
- **Framework id not enforced on reads**: a made-up `fwuid` still returned
  200 (capture `H08`). Still extract the real one from `GET /s/`;
  Salesforce can reject a stale value after a release.
- **No CAPTCHA or bot check**: the flow's JavaScript has no reCAPTCHA,
  Turnstile or hCaptcha reference; the home HTML mentions reCAPTCHA only
  inside a Content-Security-Policy allow-list. No Cloudflare or Akamai
  header or challenge appeared.
- The later `reports/tool/execute_live_send.dart` was a host-side
  `flutter_test` script that directly called `PortalSubmissionClient.send`.
  Its log and `sent_record.json` record SR C-04955177, work order W-02685560,
  and service date 2026-10-28. They are helper evidence, not a preserved raw
  successful response or proof that the native screen sent the request.
- Simulator preferences and screenshots show that SR saved locally. A saved
  SR does not establish how it was originally submitted.

## Existing request verification

The 6 November 2026 read-only search for **C-04955177** returned exactly one
City record: `caseNumber: "04955177"`, `caseType: "Illegal Dumping Item Pickup"`,
`caseStatus: "Closed"`. It completed after **90,666 ms**, with HTTP 200, Aura
`SUCCESS` and `isSuccess: true`. This clears the record-existence and observed
status blocker. The original successful submission response and native-send
provenance remain missing. Do not resend to resolve those gaps.

The earlier `search_verification.json` failed with `Input details are null`;
subsequent HTTP and official-browser searches remained pending. Those attempts
did not verify the record. The successful search uses the `userSearch` JSON-text
contract below. Detail reads require the encrypted `caseId` returned by search;
the earlier attempt using a raw Salesforce ID failed with an initialization-
vector error. A zero-row nearby query does not establish that a record is absent.

The earlier private read artifacts remain in `.playwright-mcp/city-receipt-*`;
the helper record remains in
`.scratch/illegal-dump-reporter/evidence/live_send/sent_record.json`. These hold
private/session data and are excluded from Git. The sanitized 6 November read
evidence is indexed below. No City mutation was performed during these reads.

## Public request reads (verified 6 November 2026)

These are read actions on `X11_ViewServiceRequestsController`, using the common
`POST https://myla311.lacity.gov/s/sfsites/aura` transport, form fields, guest
bootstrap and response decoding above. Use
`aura.pageURI: "/s/view-service-request"`. Call order is bootstrap, `intialDetails`,
`getSearchRequests`, then `getServiceRequestDetail` with a returned encrypted ID.
All five retained read results returned HTTP 200, Aura `SUCCESS` and Portal
`isSuccess: true`. They establish public City reads, not native Nearby or
account completion.

### Read metadata: `intialDetails`

- Method name is exactly `intialDetails`, including the spelling.
- Parameters: `{}`.
- Parsed Portal `response` is an object with `caseTypeList`,
  `caseNeigborhoodCouncilName` (exact spelling), `caseCouncilDistricts` and
  `isPortalUser`. The observed lists contained 55 service types, 99 neighborhood
  councils and 15 council districts; use fresh values rather than fixed counts.
- The guest result has `isPortalUser: true`. This metadata flag is not proof
  of login, account ownership or City authentication.
- A fresh 07:54 UTC read on 6 November returned council option values as
  strings `"1"` through `"15"`. The 99 neighborhood options are `{value,label}`
  objects, with identical labels and values in that response. Preserve exact
  values, including capitalization; do not substitute display abbreviations.

### Search: `getSearchRequests`

`params.userSearch` is JSON **text**, not an object. Its decoded shape is:

```json
{"isViewAllRequest":true,"startDate":"<YYYY-MM-DD or empty>",
 "endDate":"<YYYY-MM-DD or empty>","requestStatus":"",
 "requestType":"<service type or empty>","requestId":"<SR number or empty>",
 "councilDistrict":"","neighbourhoodCouncilName":"","isFollowRequest":false}
```

After parsing `actions[0].returnValue.returnValue`, the Portal envelope's
`response` is the **array of rows directly**, with no collection-wrapper key:

```json
{"isSuccess":true,"message":"Success","response":[
 {"caseDetailsObj":{"caseId":"<encrypted ID>","caseNumber":"<number>",
  "caseType":"<service type>","caseStatus":"<status>"},"questionList":[]}
]}
```

This is a structural example with other row fields omitted. The sanitized
artifact's `responseKind: "object"` is JavaScript's `typeof` result for an
array, not evidence of a JSON collection wrapper.

For an exact-number lookup, the successful read used the SR number as
`requestId` and empty strings for dates and all other filters, with
`isViewAllRequest: true` and `isFollowRequest: false`. The search key
`neighbourhoodCouncilName` differs from the metadata key
`caseNeigborhoodCouncilName`.

The source-exact Barricade query used `requestType: "Barricade Removal"`,
`startDate: "2026-11-05"`, `endDate: "2026-11-05"`, empty remaining string
filters and the same booleans. It returned six records. A query for
`2026-11-06` returned zero with `message: "No matching service requests found"`;
at the time of both reads, the Los Angeles date was still 5 November.
Do not use the machine's UTC or another time zone's date as the City date.
No radius, location or area API parameter was evidenced by these calls.

Fresh reads at 07:54 UTC on 6 November used the same 5 November Barricade query.
The unfiltered status result had eight records: five `Closed` and three
`Workorder Created`. `requestStatus: "Closed"` returned exactly the five Closed
records, matched using hashed identities. Literal `requestStatus: "Open"`
returned zero, despite the three Workorder Created records. All three reads
returned HTTP 200, Aura `SUCCESS` and `isSuccess: true`. This verifies Closed
filtering for that sample, but does not establish the Portal's Open encoding or
active-status grouping. Do not map the native Open label to literal `"Open"`
without verifying the rendered Portal control. Counts are snapshots, not totals
to hardcode; the earlier six-record result remains a separate observation.

### Detail: `getServiceRequestDetail`

Parameters (both strings):

```json
{"caseId":"<encrypted rows[0].caseDetailsObj.caseId>","searchRequestId":""}
```

Send the **encrypted** `caseId` returned by search; do not substitute a raw
Salesforce record ID. After the common Aura/Portal decoding, `response` is one
object, not an array. The verified detail response has a `questionList` with
two entries; the field is `questionList`, not `questionsLst`.

Search rows and the detail response share the observed keys
`workOrderUrlsList`, `urlsList`, `questionList`, `followRequestId`,
`displayMapCmp`, `displayFollowButton`, `caseUrlsList`, `caseObj` and
`caseDetailsObj`. The observed `caseObj` exposes `attributes`.
`caseDetailsObj` contains `resolutionMessage`, `markerCreatedDate`,
`legacyServiceRequestNumber`, `isSearchedByLegacyNumber`, `createdDate`,
`closureComments`, `closedDate`, `caseType`, `caseStreetAddress`, `caseStatus`,
`caseNumberWithPrefix`, `caseNumber`, `caseLongitude`, `caseLatitude`, `caseId`
and `caseAddress`. Names establish the response schema, not permission to
publish real addresses, contact data, session values or encrypted IDs.

### Retained read evidence

Sanitized artifacts reside in
`.scratch/portal-mobile-parity/evidence/barricade-contract-20261105/`.
The following are SHA-256 hashes of the sanitized files themselves, distinct
from the response hashes stored inside them:

- `nearby-initial-read-20261106.json`:
  `eb3017f7616f278b2f26f8cc586d7b5bd79d40be10a05a8a1fe9917b78d466ec`.
- `nearby-historical-read-20261106.json`:
  `d1392b459b6907d1584c92c751468f7fe52fb41ae8bfc74e10a4db3fd82c4b1b`.
- `nearby-la-day-read-20261106.json`:
  `076516f03f0bf09ac7ae1d164df333901dbe9f06e4d2670022bfbfb66d31cfc7`.
- `nearby-detail-read-20261106.json`:
  `036fc956affd5818f9f8970065cabce4349ffcf773d63530989f76bd9927e39c`.
- `nearby-bounded-read-20261106.json`:
  `4f12997cf0f57ed1e3b63bb70d987fccfcdb254a42faaede12ad78a12a9f3d81`.
- `nearby-filter-options-20261106.json`:
  `4f2ac2535950b33d9c540009b01db7817c315868796dc11b1668b635c3c533a4`.
- `nearby-status-all-20261106.json`:
  `b7eb9fed152afd93046ea142ef0b88055322a94bb8cb71f6614d61b267e3bca8`.
- `nearby-status-open-20261106.json`:
  `8477d2876457b8eefefc5358f163f39363dfcab9de75524d10a9a6973b7aa01c`.
- `nearby-status-closed-20261106.json`:
  `7cc55feb28c3e2769f69abd501291151b69de889a61655f9f8a230d9915ac8ab`.

Terms-of-use caution: this is the Portal's non-public API.

## Unknowns

- Original successful `submitCase` request/response and native-send provenance.
  The 6 November City read verifies C-04955177's existence and observed Closed
  status only. Exact types of
  `NumberIncrement` and `MultiPicklist` answers (source implies a string
  for numbers and `;`-joined text for multi-select).
- Whether the server requires `Google_Address__c`, `Access_Source__c` and
  the other client-info fields, or validates them.
- Whether the server drops answers whose `sDisplay` is false, or needs
  them removed.
- The helper result supports the production client's guest transport, but
  its missing original successful envelope prevents independent replay of
  that evidence without another write.
- `getRelatedCaseLst` response when duplicates exist, and whether a
  duplicate blocks the submit.
- Aura `ERROR` state shape (expired context, stale `fwuid`, request too
  large) and request size limit for five photos.
- `fileName` normalisation helper (`c/laUtils`) was not inspected.
- Rate limits and abuse controls.
- What the City does with `position` EXIF data (the app may send `null`).

## Captures index

Raw captures hold session values and are outside the repo, one file per
call (request and response). Folder:

```text
/private/tmp/claude-501/-Users-regiskian-Git-reports/1db0d6d5-e0e6-4607-abe3-13197d0bcd92/scratchpad/captures/
```

Each id is the filename prefix: `<id>-*.json`.

- Browser (numbers follow the capture order): `003` GET `/s/`, `011`
  `fetchInitialDetails`, `038` and `039` `fetchCaseTypeDetails`, `041`
  map iframe page, `081`, `082` and `099` `validateOriginalAddress`, `106`
  `getRelatedCaseLst`.
- Plain HTTP replays: `H01` GET `/s/`, `H02` `fetchInitialDetails`, `H03`
  `fetchCaseTypeDetails`, `H04` `validateAddress`, `H05`
  `validateOriginalAddress`, `H06` `getRelatedCaseLst`, `H07`
  `fetchInitialDetails` with no cookies, `H08` `fetchInitialDetails` with
  a made-up `fwuid`.
- The original October source reference was an unescaped report-issue LWC
  bundle in temporary storage. For current shared details/submit preparation,
  use the retained 6 November module-loader response and SHA-256 recorded in
  the Barricade source section above. That response includes
  `c/laRiDetails.handleContinue()` and `c/laCaseCreationFlow.submitRequest()`;
  it does not supply a successful City submit transaction.
