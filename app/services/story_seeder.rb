# Seeds the branching narrative for the Story Engine demo. Real, written copy —
# no lorem. "The Last Signal": you are the lone night-shift operator at a remote
# Arctic listening station when something answers back.
class StorySeeder
  SLUG = "the-last-signal".freeze

  SCENES = [
    {
      key: "start", mood: "calm",
      heading: "0247 hours — Vega Station",
      body: <<~TEXT,
        The kettle ticks as it cools. Outside, the wind has finally dropped, and the
        silence that replaces it is somehow louder. You are forty days into a ninety-day
        rotation at the northernmost listening post on the continent — a single insulated
        hut, a dish the size of a house, and you.

        At 0247 the spectrum analyzer chirps. A narrowband tone, dead center on a frequency
        that is supposed to carry nothing but cosmic hiss. It is not noise. It is patterned.
        It repeats every nine seconds, patient as a heartbeat.

        Your coffee goes cold in your hand.
      TEXT
      choices: [
        { label: "Log it, record a sample, and keep watching", target: "record" },
        { label: "Radio Command immediately — wake them up", target: "radio_command" },
        { label: "Try to answer it yourself", target: "answer_now" }
      ]
    },
    {
      key: "record", mood: "tense",
      heading: "The pattern resolves",
      body: <<~TEXT,
        You let it run. Three minutes of tape, then five. The recorder's reels turn with
        a sound like a sleeping animal breathing. When you slow the playback down, the
        nine-second pulse fractures into structure — short, long, short — a grammar
        underneath the tone.

        It is counting. Down. From a number you can't yet read.

        The station log demands an entry. Your pen hovers over the page.
      TEXT
      choices: [
        { label: "Decode the countdown before you do anything else", target: "decode" },
        { label: "Now radio Command — this is bigger than you", target: "radio_command" },
        { label: "Walk outside and look at the dish", target: "dish" }
      ]
    },
    {
      key: "answer_now", mood: "eerie",
      heading: "You key the transmitter",
      body: <<~TEXT,
        You don't think. You reach for the transmitter and tap out the only thing your
        hands remember: the first eight digits of pi, the universal "we are here, and we
        can count." Your thumb leaves the key.

        Nine seconds. The tone stops.

        Then it returns — but changed. It has taken your rhythm and folded it into its own,
        the way a stranger finishes your sentence. Whatever is out there heard you. And it
        is closer now; the signal strength has doubled.
      TEXT
      choices: [
        { label: "Send more — establish a real exchange", target: "exchange" },
        { label: "Stop. You may have made a terrible mistake", target: "radio_command" }
      ]
    },
    {
      key: "radio_command", mood: "tense",
      heading: "Static where Command should be",
      body: <<~TEXT,
        You switch to the command channel and depress the handset. "Vega Station to Control,
        priority traffic, do you copy." Your voice sounds small in the hut.

        Nothing. Not even the usual carrier hum. The channel that has carried a bored
        duty officer's voice every six hours for forty days is simply gone — as if the rest
        of the world has been unplugged.

        Only the nine-second tone remains, bleeding faintly across every band now.
      TEXT
      choices: [
        { label: "Check whether the outage is on your end", target: "diagnose" },
        { label: "Go back and engage the signal — it's all that's left", target: "exchange" }
      ]
    },
    {
      key: "decode", mood: "tense",
      heading: "Reading the countdown",
      body: <<~TEXT,
        You spread the printout across the desk and work the math by hand, because the
        terminal feels suddenly untrustworthy. The structure is base-twelve. The number,
        when you finally have it, is not large.

        It is a duration. Two hours, eleven minutes, and falling.

        A countdown implies an event. And an event, out here, implies that something has
        decided you are close enough to matter.
      TEXT
      choices: [
        { label: "Aim the dish at the source and listen harder", target: "dish" },
        { label: "Prepare to transmit a reply before the clock runs out", target: "exchange" },
        { label: "Pack a survival kit and get ready to run", target: "flee" }
      ]
    },
    {
      key: "dish", mood: "eerie",
      heading: "Under the dish",
      body: <<~TEXT,
        You suit up and step into the dark. The aurora is doing something you have never
        seen — not curtains but rings, concentric, centered directly overhead on the dish.
        The great white bowl is faintly warm to the touch through your glove, humming at
        the exact pitch of the signal.

        At the focal point, where there should be nothing but the feed horn, a small steady
        light has appeared. It was not there yesterday. It pulses every nine seconds.
      TEXT
      choices: [
        { label: "Climb up and bring the light back inside", target: "artifact" },
        { label: "Leave it. Retreat to the hut and seal the door", target: "diagnose" }
      ]
    },
    {
      key: "diagnose", mood: "tense",
      heading: "Tracing the fault",
      body: <<~TEXT,
        You go down the checklist the way training drilled into you. Power: nominal.
        Antenna feedline: nominal. Backup oscillator: nominal. Every system insists it is
        healthy, which means the silence on the command channel is not a fault.

        It is a choice. Something is holding the line open and empty, the way you'd cover a
        person's eyes so they only see what you want them to see.

        The countdown, wherever it is, has not stopped.
      TEXT
      choices: [
        { label: "Refuse to be steered — transmit on every band at once", target: "exchange" },
        { label: "Conserve power, hunker down, and wait it out", target: "wait" }
      ]
    },
    {
      key: "exchange", mood: "eerie",
      heading: "A conversation, of a kind",
      body: <<~TEXT,
        You begin to trade. A prime number for a prime number. A position for a position.
        Each time, the reply comes faster, until the nine-second gap collapses and you are
        no longer taking turns — you are speaking together, two instruments tuning to one
        pitch.

        And then, between one breath and the next, you understand a single clean idea that
        was not in any of the math: it is not far away. It has been routed through the dish,
        through the wire, into the warm dark behind your eyes. It would like to come the
        rest of the way.
      TEXT
      choices: [
        { label: "Open the door the rest of the way. Say yes.", target: "ending_merge" },
        { label: "Pull the main breaker and cut every circuit", target: "blackout" }
      ]
    },
    {
      key: "artifact", mood: "eerie",
      heading: "The light in your hands",
      body: <<~TEXT,
        It comes free of the feed horn with a soft reluctance, like a fruit from a branch.
        In your palm it is the size of an egg, perfectly smooth, neither warm nor cold, and
        it weighs nothing at all. The nine-second pulse is inside it.

        Back in the hut, under the lamp, it stops pulsing. It waits. You have the distinct,
        unscientific sense that it is being polite — that it will do nothing you do not
        first invite.
      TEXT
      choices: [
        { label: "Place it on the transmitter and let it speak through the dish", target: "exchange" },
        { label: "Lock it in the sample safe and report only the facts", target: "ending_steward" }
      ]
    },
    {
      key: "flee", mood: "grim",
      heading: "Forty kilometers of dark",
      body: <<~TEXT,
        You take the snowmobile, a fuel can, the emergency beacon, and your nerve. The
        station shrinks behind you to a single lit window, then to nothing. For twenty
        minutes there is only the headlight and the white.

        Then the beacon in your pack begins to pulse. Every nine seconds. You never turned
        it on.

        It is not in the station. It was never in the station. It is wherever you are.
      TEXT
      choices: [
        { label: "Stop running. Turn around. Face it on your own terms", target: "exchange" },
        { label: "Throw the pack into the snow and keep going", target: "ending_lost" }
      ]
    },
    {
      key: "wait", mood: "grim",
      heading: "When the clock reaches zero",
      body: <<~TEXT,
        You kill the non-essential systems and sit in the half-dark, watching the
        countdown you reconstructed from the tape tick toward nothing. You tell yourself
        that not answering is itself an answer. That silence is a wall.

        At zero, the tone does not crescendo. It simply stops. And in the new quiet you
        hear, very clearly, three slow knocks on the outer door of a station that is forty
        kilometers from another living soul.
      TEXT
      choices: [
        { label: "Open the door", target: "exchange" },
        { label: "Stay absolutely still and never open it", target: "ending_vigil" }
      ]
    },
    # --- Endings (no choices) ---
    {
      key: "ending_merge", mood: "eerie", ending: true, ending_kind: "Communion",
      heading: "Ending — Communion",
      body: <<~TEXT,
        You say yes, and the saying is the last thing that is only yours. The signal does
        not consume you; it joins you, the way two melodies become a chord that neither
        could be alone. When the relief team reaches Vega Station in the spring, they find
        the logs immaculate, the kettle full, and the operator gone — though the dish, they
        report, now points itself, and hums a patient nine-second song to a sky that, lately,
        seems to be listening back.
      TEXT
    },
    {
      key: "blackout", mood: "grim", ending: true, ending_kind: "The Long Silence",
      heading: "Ending — The Long Silence",
      body: <<~TEXT,
        You pull the breaker. The hut goes black and dead and utterly, gloriously silent.
        No tone. No pulse. Just your own ragged breathing and the tick of cooling metal.
        You hold the dark like a held breath until dawn grays the window. Whatever it was,
        you did not let it in. You also have no recording, no proof, and ninety days minus
        forty to convince yourself it was real. The relief team will find a sane, exhausted
        operator and an instrument log with one impossible, unverifiable line. Some doors
        are worth the cost of keeping shut.
      TEXT
    },
    {
      key: "ending_steward", mood: "hopeful", ending: true, ending_kind: "The Steward",
      heading: "Ending — The Steward",
      body: <<~TEXT,
        You lock it away and you write only what you can defend: time, frequency, signal
        strength, the warm light at the focal point, the egg of impossible weight now sealed
        in the sample safe. You do not speculate. You do not answer. When Command's channel
        finally crackles back to life at 0600, you read your report in a flat, careful voice,
        and you let the people whose job it is decide what comes next. It is not the brave
        ending, or the romantic one. It is the responsible one — and the artifact, when the
        scientists open the safe, is still patiently, politely waiting.
      TEXT
    },
    {
      key: "ending_lost", mood: "grim", ending: true, ending_kind: "Whiteout",
      heading: "Ending — Whiteout",
      body: <<~TEXT,
        You throw the pack and you run, and the pulsing stops, and for one bright second you
        believe you have won. Then the headlight catches the snowmobile's own track, curving,
        and you understand you have been driving in a slow circle for some time. The fuel
        gauge sits near empty. Behind you, far off, a single window glows — the station you
        left, the only warmth for forty kilometers, the place you can no longer reach. The
        cold is not unkind. It simply does not negotiate. You should have turned around.
      TEXT
    },
    {
      key: "ending_vigil", mood: "eerie", ending: true, ending_kind: "The Vigil",
      heading: "Ending — The Vigil",
      body: <<~TEXT,
        You do not open the door. Not at the third knock, not at the thirtieth, not when the
        knocking becomes a voice that uses, gently, your mother's name for you. You sit with
        your back against the cold steel and you keep the wall between you and it for the rest
        of the long night, and the longer rotation, and you make it home. You are fine. You
        are completely fine. It is only that, ever since, in any quiet room, you find yourself
        counting — one, two, three — and waiting, without meaning to, for the answer that did
        not come and the door you did not open.
      TEXT
    }
  ].freeze

  def self.reset!
    Story.where(slug: SLUG).destroy_all

    story = Story.create!(
      slug: SLUG,
      title: "The Last Signal",
      tagline: "Interactive fiction · ~5 minutes · 5 endings",
      blurb: "You are the lone night-shift operator at a remote Arctic listening station " \
             "when something on a dead frequency begins, patiently, to answer back. " \
             "Every choice is a Turbo navigation with a cinematic View Transition; the " \
             "ambient-audio bar never reloads; the live tally shows what other readers chose."
    )

    SCENES.each do |attrs|
      scene = story.scenes.create!(
        key: attrs[:key],
        heading: attrs[:heading],
        body: attrs[:body],
        mood: attrs[:mood],
        ending: attrs.fetch(:ending, false),
        ending_kind: attrs[:ending_kind]
      )

      Array(attrs[:choices]).each_with_index do |c, idx|
        scene.choices.create!(label: c[:label], target_key: c[:target], position: idx)
      end
    end

    story
  end
end
