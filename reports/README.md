# MyLA311

A Flutter mobile app for Los Angeles city-service discovery, guided report
journeys and saved records. Illegal dumping uses the City's guest Aura API directly;
other service journeys and account tools remain local previews. For
illegal dumping, photos and description are optional; location, valid debris
answers and a contact choice are required. Contact can be anonymous or named.

The native interface follows the canonical v2 design: an orange Home, service
catalog, six dumping steps (Location, Items, Photos, Details, Contact, Review),
and saved Reports with Receipts. Mona Sans is bundled for offline use. Motion
follows device settings and the saved preference under the Home gear. Help
includes searchable guidance, City contact information and safe handling of
unconfirmed submissions.

Other-service previews retain optional details, landmarks and local follow
preferences. Creating a local receipt requires explicit confirmation that nothing
is sent to the City. Preview lookup uses an exact local ID, never a City Service
Request number. Services with unverified access requirements show information
without a new preview action.

## Run and check

From this directory, with Flutter providing Dart >=3.11.4 and <4.0.0:

```sh
flutter pub get
flutter test --coverage --branch-coverage test/
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter devices
```

Select an available iOS simulator from the device list, then run
`flutter run -d DEVICE_ID` with its ID. Use the newest compatible installed
runtime.

Offline tests replace the Portal connection and device plugins. The production
illegal-dumping flow sends a real City request when Submit is pressed. Never
run historical live-send helpers as tests. Required coverage is 100% production
lines and at least 80% branches, without exclusions. Keep the Podfile's iOS 15.0
deployment-target override.

The controlled native entry point at `test/support/submit_home_native_fixture.dart`
uses the development-only Flutter driver and local report storage. Run it only
on a dedicated QA simulator, never on a resident's installation. The shipped
entry point remains `lib/main.dart`.

## Submission recovery

The app retains reports and receipts locally. An exclusive attempt marker is
written and flushed before dispatch. An unconfirmed result stays distinct from
Not sent and Submitted across ordinary app/process restarts and blocks another
send. A damaged marker also blocks dispatch. This does not guarantee survival
of device power loss.

Known pre-submit failures and explicit rejections without a possible receipt
remain editable. The Portal offers no requester cancellation; contact 3-1-1
when a submitted or unconfirmed request needs investigation.

