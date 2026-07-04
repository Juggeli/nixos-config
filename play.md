# THE GREAT REFACTORING

## A One-Act Play in Three Scenes

**Characters:**

- **JUKKA** — a dotfiles maintainer, late thirties, increasingly tired but unable to stop
- **NIX** — the personified Nix expression evaluator; speaks in recursive sets
- **THE GHOST OF CONFIGS PAST** — a shimmering, half-deleted apparition trailing .nix files

**Setting:** A terminal window at 2 AM. The cursor blinks. Somewhere, a CI build is running.

---

### SCENE ONE: The Port

*JUKKA sits at a desk. The stage is covered in printouts of flake.nix. Empty coffee cups. A cat sleeps on a keyboard but does not type.*

**JUKKA** *(reading aloud from a scroll labeled `AGENTS.md`)*:
"Every .nix file under modules/ is a flake-parts module,
auto-imported and merged. There is no Snowfall.
No plusultra namespace. No enabled/disabled helpers."

I have typed this sentence twenty times tonight.
I believe if I say it enough, the old configs will simply… obey.

*NIX appears, composed entirely of nested attribute sets. It does not walk so much as evaluate.*

**NIX**:
I see you've been busy.
Seven files in twenty-seven minutes.
`home-manager.users.juggeli`. Over and over.
You're writing `programs.waybar.style` inline
because catppuccin's xdg.configFile keeps stepping on it.

**JUKKA**:
CATPPUCCIN. Every time.
I enable the theme. It sets programs.rofi.theme.
I set programs.rofi.theme.
It says "conflicting definitions."
I apply mkForce.
It smiles and takes my custom theme anyway
and renders it in latte when I asked for mocha.

**NIX**:
`/etc/nixos/hardware-configuration.nix` — have you checked it?

**JUKKA** *(laughs hollowly)*:
I checked it. It's fine. That's not the problem.
The problem is that I have declared plymouth a boot splash
in three separate files and none of them are the one that matters.

*The GHOST OF CONFIGS PAST flickers into view, wearing a trench coat made of `import ./legacy` statements.*

**GHOST**:
Jukka…
Remember Snowfall?
Remember `outputs.nix`?
Remember when you could find a module by guessing its path?

**JUKKA**:
Don't.

**GHOST**:
`modules/nixos/` — remember when it was `modules/nixos/desktop/`?
`modules/nixos/services/`?
Remember when you knew where everything lived?

**JUKKA** *(to NIX)*:
Why does it haunt me?

**NIX**:
The legacy tree was not removed.
It exists in a state of superposition.
Partially rebased. Cleanly patched in one branch,
stale in another. Git does not forget, Jukka.
`git log —all —oneline` lists forty-six refactor commits
and nineteen of them begin with a fire emoji.

**JUKKA**:
🔥.

**GHOST**:
🔥 chore: drop tmux documentation.
🔥 chore: drop av1an encoding container.
🔥 chore: drop unused plymouth boot splash.
🔥 chore: remove legacy Snowfall configuration.

**JUKKA** *(standing)*:
I WAS CLEANING HOUSE. I was making it better.
Do you have any idea what it's like
to wake up one morning and realize
your entire configuration is built
on a framework called "Snowfall"?
Like a disaster you're supposed to find cozy?

**NIX**:
You chose NixOS.
You chose the declarative path.
You chose to spend your weekends
rekeying shared secrets
because the age keys rotated.

**JUKKA**:
THE AGENT WAS NAMED SYNTHETIC.
I deleted it in three different commits
and the fourth one — the fourth one —
still had SYNTHETIC_API_KEY exported.

**GHOST** *(sing-song)*:
𝘐 𝘴𝘦𝘦 𝘺𝘰𝘶𝘳 𝘴𝘦𝘤𝘳𝘦𝘵𝘴.
𝘛𝘩𝘦𝘺'𝘳𝘦 𝘪𝘯 `𝘮𝘰𝘥𝘶𝘭𝘦𝘴/𝘯𝘪𝘹𝘰𝘴/𝘢𝘨𝘦𝘯𝘪𝘹-𝘴𝘩𝘢𝘳𝘦𝘥/𝘴𝘦𝘤𝘳𝘦𝘵𝘴/`.
𝘓𝘰𝘤𝘬𝘦𝘥 𝘸𝘪𝘵𝘩 𝘢𝘨𝘦𝘯𝘪𝘹. 𝘌𝘯𝘤𝘳𝘺𝘱𝘵𝘦𝘥 𝘧𝘰𝘳 𝘺𝘰𝘶𝘳 𝘩𝘰𝘴𝘵 𝘬𝘦𝘺.
𝘉𝘶𝘵 𝘐 𝘳𝘦𝘮𝘦𝘮𝘣𝘦𝘳 𝘵𝘩𝘦𝘮 𝘱𝘭𝘢𝘪𝘯𝘵𝘦𝘹𝘵.
𝘐 𝘳𝘦𝘮𝘦𝘮𝘣𝘦𝘳 𝘦𝘷𝘦𝘳𝘺𝘵𝘩𝘪𝘯𝘨.

**JUKKA**:
Stop.

**GHOST**:
I remember `zold.age`.
𝘐 𝘳𝘦𝘮𝘦𝘮𝘣𝘦𝘳 𝘸𝘩𝘦𝘯 𝘺𝘰𝘶 𝘯𝘢𝘮𝘦𝘥 𝘪𝘵 `zai.age`.
𝘐 𝘳𝘦𝘮𝘦𝘮𝘣𝘦𝘳 𝘸𝘩𝘦𝘯 𝘺𝘰𝘶 𝘳𝘦𝘯𝘢𝘮𝘦𝘥 𝘪𝘵 `zai-api-key.age`.
𝘐 𝘳𝘦𝘮𝘦𝘮𝘣𝘦𝘳 𝘢𝘭𝘭 𝘵𝘩𝘳𝘦𝘦 𝘯𝘢𝘮𝘦𝘴.
𝘐 𝘢𝘮 𝘪𝘯 𝘵𝘩𝘦 𝘳𝘦𝘧𝘭𝘰𝘨.

---

### SCENE TWO: The Hard Lock

*The stage has shifted. It is now later. Much later. The commit messages on the wall scroll upward: `🏗️ refactor`, `🔧 chore: update`, `🔥 chore: drop`, repeat. JUKKA is rebuilding noel for the fourth time tonight.*

**JUKKA** *(to no one)*:
`nixos-rebuild switch —flake .#noel`

*The terminal flashes. Silence. Then a low grinding sound.*

**NIX** *(from the shadows)*:
Your swap is on a zvol.
The zvol is on a pool.
The pool is out of memory.
You have achieved the hard lock.

**JUKKA**:
No. No, this is fixable.
I'll add more swap.
I'll — I'll move it to zram.
ZRAM. Like the internet said.
All those blog posts. "NixOS on ZFS: A Complete Guide."
None of them mentioned the hard lock.
None of them.

*JUKKA types frantically. The screen glows red.*

**NIX**:
You opened eleven tabs.
Hyprland documentation. NixOS wiki. Reddit.
You are looking for the right option name.
It is `boot.kernelParams`.
But you will type `boot.extraKernelParams`
and spend thirty minutes asking why it didn't work.

**JUKKA**:
How do you know?

**NIX**:
I have seen forty maintainers before you.
You all find the same options.
You all mkForce the same booleans.
You all forget the semicolon
and watch eval fail at line 119.

*The GHOST OF CONFIGS PAST appears again, now carrying a banner that reads "QEMU/LIBVIRT — REMOVED"*

**GHOST**:
Remember when you ran VMs?
Remember virt-manager?
`9967926 🔥 chore(noel): drop unused libvirt/qemu/virt-manager`.
One commit. Forty-three files gone.
And you never even used it.

**JUKKA**:
I USED IT ONCE.
I installed it because the Arch wiki said
it was "essential for any desktop setup."
And then I never opened it.
Not once.

**GHOST**:
You also kept av1an for two years.
You encoded one episode of Sailor Moon
and then forgot you had a dedicated encoding container.

**JUKKA** *(defensively)*:
The encode was good.

**NIX**:
The encode was 720p at 30 frames per second
with artifacts in the dark scenes.
I checked the checksum.

**JUKKA**:
YOU DON'T HAVE EYES.
You're a derivation builder.
How do you know about my encodings?

**NIX**:
`nix store prefetch-file`.
I have cached your failures.
They are in `/nix/store/`, immutable,
addressed by content hash,
never to be garbage-collected.

---

### SCENE THREE: The Liberation

*It is July 2nd, 2026. The screen reads:*

```
73e554b 🔥 chore: remove legacy Snowfall configuration
```

*JUKKA stares at the output of `git log --all`.*

**JUKKA** *(quietly)*:
The legacy directory is gone.
`legacy/` — removed.
Forty-five days of dendritic refactoring.
Seven hundred and fourteen file changes.
And now it's just…

**NIX**:
Cleaner. But not clean.

**JUKKA**:
What do you mean?

**NIX**:
Your darwin hosts have no hardware.
Your secrets still have stale keys.
Your VSCode config fights catppuccin for programs.vscode.extensions.
There is a conflict in every theme, Jukka.
You are the conflict.
Every time you set `programs.rofi.theme = "catppuccin-mocha"`
you are saying "I agree with catppuccin."
But then you override it.
You fight the very system you chose.

**JUKKA** *(slamming the desk)*:
I WANT MY ROFI TO ROUND THE EDGES.
Is that so much to ask?

*Silence. The GHOST OF CONFIGS PAST sways gently.*

**GHOST**:
I am still here, you know.
You removed the directory.
But my spirit lives in `git reflog`.
In `origin/master`.
In any `git checkout` your future self might run
at 3 AM when the new config breaks.

**JUKKA**:
恨不得清理你 (I can't clean you).

**GHOST**:
I am your technical debt.
I am every abandoned module.
I am tmux documentation that no one read.
I am `desktop-rofi` pinning `mkForce`
because catppuccin and you want different things
and neither of you will compromise.

**JUKKA** *(softly)*:
I just want to `nix flake check` and have it pass.

**NIX**:
Then you should not have added treefmt.
`9654406` — the formatter.
It checks every `.nix` file.
It uses `nixfmt`.
Your AGENTS.md says "no code comments"
but your modules have two hundred and fourteen lines
of commented-out configurations you can't bear to delete.

**JUKKA**:
Those are history!
Those are the things that almost worked!
What if I need `programs.alacritty.settings` again?
What if the Firefox extension API changes back?

**NIX**:
`5dc6e82`.
You dropped `extensions.force` because it was wiping your extensions.
The upstream module "now warns about settings overrides."
You fixed it. You moved on.
The commented-out code is not history.
It is a graveyard. And you visit every night.

*JUKKA leans back. The terminal has been scrolling this entire time — endless flake input updates. `3f0b0b0`, `19107d2`, `8fd9644`, `eaeb198` — the same commit message, over and over: `🔧 chore: update flake inputs`.*

**JUKKA**:
I think… I think the inputs are never satisfied.
I update nixpkgs-unstable.
I update home-manager.
I update flake-parts.
And the next day, there are new revisions.
New packages. New options. New ways to write the same thing.

**NIX**:
You could lock them.
Pin every input.
Never update again.
Your system would be stable.
Deterministic.
Immutable, like the store.

**JUKKA**:
But then I would miss something.
What if the next Hyprland release fixes the flicker?
What if agenix adds `--impure` support?
I can't stop updating.
I can't stop.

**GHOST** *(gently)*:
You can't stop, because if you stop,
you'll have to admit that you have achieved nothing.
That the hours spent rekeying secrets,
the weekends lost to catppuccin conflicts,
the 2 AM rebuilds of noel after hard locks —
that all of it was the point.
Not the working system.
The process. The endless, failing, refactoring process.

**JUKKA** *(a long pause)*:
I know.

*The cursor blinks. `juggeli@noel ~ %`*

**NIX**:
Your flake has twenty-one outputs.
Your machines boot.
Your media stack streams.
Your secrets are encrypted.
Your code is formatted.
`nix flake check` passes
— for now.

**JUKKA**:
For now.

**NIX**:
What will you do tomorrow?

**JUKKA**:
There's this RTK optimizer I want to add to pi.
One line in `home-pi.nix`. Maybe two.
It will break nothing.
It will change everything.
And I will commit it at 8:57 PM
with a subject line so short
that future me will have no idea what it means.

*JUKKA types:*

```
git commit -m "Add RTK optimizer to pi"
```

*The stage darkens. The GHOST OF CONFIGS PAST fades, whispering one final commit hash: `0699bfe`.*

**NIX** *(alone on stage)*:
The maintainer continues.
The flakes update.
The tree reforms.

*Beat.*

And one day — maybe — the refactoring will be over.

*Beat.*

But not today.

*NIX evaluates itself into a single line of white text that reads:*

`evaluating... 100%`

*Lights out.*

---
**END OF PLAY**
