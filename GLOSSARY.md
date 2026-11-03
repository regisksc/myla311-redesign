# MyLA311

A native app for Los Angeles residents to discover MyLA311 services and report
city problems. Illegal dumping has a City Submission client. Other service
journeys remain local previews until their City integrations are verified.

## Language

**Report**:
The record a person creates in the app for one city problem: its request type,
what it is, where it is, when, and optional photos. It stays on the phone with its
delivery state and any confirmed Service Request number.
_Avoid_: Ticket, request, case

**Draft**:
An unfinished Report that a person can continue before sending it to the city.
_Avoid_: Submission, queued request

**Submission**:
A Report accepted by MyLA311. A Report becomes a Submission only when the
city's system confirms it.
_Avoid_: Filing, upload

**Submission unconfirmed**:
The app retained an attempt whose City acceptance was not confirmed. The
person must check the existing request before another send. This state also
survives an ordinary app restart.
_Avoid_: Not sent, failed (neither proves the City did not receive it)

**Service Request**:
The city's own record of a Submission, identified by an SR number. The city
creates it; the app never does.
_Avoid_: Report (that word is the app's local record)

**Receipt**:
The confirmation of an accepted Submission, including its Service Request
number.
_Avoid_: Service Request (the city's record), unconfirmed attempt

**Illegal Dumping Pickup**:
The MyLA311 request type currently supported by the native Submission client.
Residents select it from the service catalog. Other type labels must never
be sent through the illegal-dumping payload.
_Avoid_: Issue Type, category

**Request type**:
The City's named service selected for a Report. Its verified questions,
eligibility and Submission contract determine the native journey.
_Avoid_: Issue Type, category

**Service catalog**:
The City's current request-type names and service groups, read through the
guest Portal session. Discovery does not prove a type can be submitted.
Session-encrypted identifiers are transport values, not saved type identities.
_Avoid_: Submitted services, accepted requests

**Local preview**:
A device-only example for a service without a verified City Submission client.
Its lookup ID identifies a local record, not a Service Request. Choosing preview
email updates saves a local preference and sends no email.
_Avoid_: Submitted Report, City Receipt

**Portal**:
The MyLA311 web app at myla311.lacity.gov, the city's public way to file a
Service Request.
_Avoid_: Website
