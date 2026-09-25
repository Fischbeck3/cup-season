# App Store presentation candidates

Eight RGB PNGs at **1320 × 2868**, composed from the actual app on an iPhone 17 Pro Max simulator. These are local review candidates; no upload or submission was made.

The size is accepted for the 6.9-inch class in [Apple’s screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), checked September 24, 2026.

| Order | Headline | Supporting caption | PNG |
|---|---|---|---|
| 1 | Your people. All season. | A season with your own group. | [Open](store/01-season.png) |
| 2 | A round starts here. | Choose the course, tees, group and game. | [Open](store/02-setup.png) |
| 3 | Keep the group’s card. | Enter scores as the round unfolds. | [Open](store/03-live.png) |
| 4 | Send the round. | A card to share from your round. | [Open](store/04-share.png) |
| 5 | The season, week by week. | Open The Book to follow the record. | [Open](store/05-weeks.png) |
| 6 | See how points add up. | Today's counting points, placed by week. | [Open](store/06-race.png) |
| 7 | Every point has a receipt. | Open a round to see its scoring details. | [Open](store/07-receipt.png) |
| 8 | Keep the season. | Return to the record after the finish. | [Open](store/08-finished.png) |

## What the images demonstrate

1. A season page with squads and golfer standings.
2. Course, tee, group and game preparation; a reachable Tee off action.
3. The supported Just score mode with four golfers.
4. The actual native round-card preview.
5. Weekly contributions in The Book.
6. The Book’s current counting points grouped by played week. This is not a historical rank chart.
7. An accepted-round receipt showing the points and their supporting figures.
8. The completed-season page and its final table.

All golfers and records are invented fixtures. Course/rating values are layout data, not an assertion about the course’s current rating. The abstract photo fixture is excluded from store images. Captures preserve the complete app image in its original aspect ratio; only scaling and the surrounding caption layout are applied.

The store copy makes no speed, earnings, handicap-improvement or historical-standings claim. The screenshot order, headlines and overall presentation are ready for the owner’s review before release.

## Reproduce

From this branch, build the app with XcodeGen and Xcode, install on an isolated iPhone 17 Pro Max simulator, then run `capture-native.py --device <device-id> --phone store`. Run `build-store.py`, followed by `build-gallery.py`. The manifest records the launch arguments and PNG hashes. The scripts use the repo’s fonts and token source; they add no production dependency.
