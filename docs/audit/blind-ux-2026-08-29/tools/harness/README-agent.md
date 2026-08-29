# How to use the app as a user (for blind testing agents)

The app is served at **http://127.0.0.1:8791/** (a phone-sized headless browser).
You drive it with a tiny CLI. Every command is a Bash call. Run everything from:

    cd /private/tmp/claude-501/-Users-fischbeck3-cup-season/8472110b-9333-460b-8c1c-e243ac7cb2f3/scratchpad/harness

Start YOUR OWN session once (use the session name you were given, e.g. `a1`):

    node bx.mjs start a1
    node bx.mjs a1 goto http://127.0.0.1:8791/
    node bx.mjs a1 wait 2500

Then look and act, one step at a time, exactly like a person would:

    node bx.mjs a1 shot door          # saves a PNG; then use the Read tool on the printed path to LOOK at it
    node bx.mjs a1 text               # the readable text on screen ([brackets] = tappable buttons/links)
    node bx.mjs a1 tree               # accessibility tree: what can be tapped, what the fields are called
    node bx.mjs a1 click "Continue with email"        # click by visible text
    node bx.mjs a1 click "role=button name=Go"        # click by role + accessible name
    node bx.mjs a1 click css=#someId                  # click by CSS selector (last resort)
    node bx.mjs a1 fill "you@email.com" me@x.com      # fill an input by placeholder/label/CSS
    node bx.mjs a1 press Enter
    node bx.mjs a1 scroll 600                         # scroll down (negative = up)
    node bx.mjs a1 back
    node bx.mjs a1 url
    node bx.mjs a1 console                            # any console errors since last check
    node bx.mjs a1 stop                               # when you are completely done

Notes that matter:
- **Screenshots are the truth.** `text`/`tree` may include content that is hidden BEHIND
  a modal dialog or off-screen. If a `dialog` is open in `tree`, the user only sees the dialog.
- After every meaningful action, take a `shot` and Read it — judge what a human would see.
- The app is a single page; "screens" change without the URL changing. Use `shot`/`text` to know where you are.
- If a click says nothing matches, run `tree` and use the exact accessible name, or `css=`.
- Use the `Read` tool on the PNG path to actually see the screenshot.
- A `text` dump longer than ~12k chars is truncated; `scroll` and re-run.
- Timestamps: run `date -u` when you want to record how long something took.

Sign-in codes (only if your instructions include an email account):
- Enter the email on the sign-in screen and press Go. Then fetch the 8-digit code with the Gmail
  search tool: query `from:noreply@cupseason.app newer_than:20m` and read the newest message's snippet
  addressed to YOUR email. Enter it in the code box. Codes expire; the newest one wins.
