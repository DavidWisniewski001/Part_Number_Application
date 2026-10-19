# UI Design

Interactive prototype (six clickable screens): https://claude.ai/artifact/3FHNbdEuzyktgNGggdv4pK
The prototype source is in `docs/ui-prototype/`. It is reference only, not production code. The WPF app reproduces the layout and behavior described here.

## 1. Principles
1. **Search first.** The app opens on *Find parts*. Creating a part is one click away, but people should look first.
2. **Pick, don't type.** Attributes are buttons or lists of allowed values. Only the manufacturer part number and links are free text.
3. **Show the result while working.** The description preview updates on every choice. The format builder shows real example numbers.
4. **The part number appears only when it is issued.** No numbers are reserved or wasted on parts that are never created.
5. **Plain language.** No SQL or table jargon in the main flow. Catalog column names appear only on the review step and under "Technical details".
6. **Reassure about AutoCAD Electrical.** The connection screen says plainly that nothing is created on the server.
7. **Never a dead end.** "No results" offers *Create a new part*. A row without a number offers *Assign a number*. A duplicate warning offers *Use the existing part*.

## 2. Layout and look
- Left navigation (dark), content on a light gray background, white panels.
  - Main items: Find parts, New part, Assign numbers, Export to ERP.
  - Setup items: Part number format, Server connection. Admins only (Q-006).
- Status bar on Find parts: connection, active format, read/write or read-only mode.
- Type: IBM Plex Sans for UI text, **IBM Plex Mono for part numbers, MPNs and catalog fields**. Monospace makes numbers easy to read and compare.
- Colors: ink `#1A1F24`, muted `#59636E`, lines `#D9DDD8`, one accent blue `#1F4FBF` (selected and primary), warning orange-brown `#9A4A00` / `#FFF1E0`, success green `#134D2A` / `#EAF5EE`. All text meets 4.5:1 contrast.
- Buttons are at least 44 px high. Everything works by keyboard. Icon-only buttons have accessible names.
- The window works at 1024 px wide. Side panels wrap below the main content on narrow windows.

## 3. Screens

### 3.1 Find parts (home)
- Large search box: part number, description, manufacturer or MPN. Results filter as the user types.
- Category chips (All, Relay, Breaker, …) taken from the categories in the settings file.
- Results table: Part number · Description · Manufacturer · Mfr part no. · Catalog table. Rows without `USER1` show **"No number yet"** in orange.
- Detail panel for the selected row: large part number with **Copy**, description, manufacturer, MPN, category, table, attributes. Actions: *Create similar part*, *Open datasheet*. For rows without a number: *Assign a number*.
- Empty result: an explanation plus a *Create a new part* button.

### 3.2 New part (wizard)
The steps rail on the left lets the user go back to any completed step. A **live description preview** sits on the right on every step.
1. **Category:** tiles showing name, prefix and catalog table.
2. **Details:** one group of option buttons per attribute, in the order the description standard defines. Attributes that can be left out of the short description are labelled as such.
3. **Manufacturer:** a controlled list (aliases recognized). MPN as printed, with the normalized form shown. Optional datasheet link.
4. **Duplicate check:** a warning card with the matching part and the reasons it matched, and *Use [existing PN] instead*. To continue anyway, the user must write a reason (policy Q-010). Otherwise a green "No matching parts found".
5. **Review and issue:** exactly the catalog fields that will be written (`CATALOG`, `MANUFACTURER`, `DESCRIPTION`, mapped attribute columns, `USER1`). Button: **Issue part number**.
6. **Done:** a large part number with *Copy*, *Create a similar part* (keeps the values), *Start a new part*, and *Back to Find parts*.

Preview panel: the short description with a live counter "n / 40", and the long description. When attributes are dropped to fit, it says which ones.

### 3.3 Assign numbers
- Tab **Rows without a number:** selectable rows. The proposed number for each selected row shows in gray "(on assign)". Button: **Assign N numbers**. Afterwards the numbers show in green, plus a confirmation.
- Tab **Numbers that need attention:** `USER1` values in an old scheme, a wrong format, or used twice. Per row: *Replace with new number* / *Leave as is*. Nothing changes until the user acts.

### 3.4 Server connection (first run, then under Setup)
- First-time steps: 1 Connect → 2 Choose format → 3 Start.
- Server, catalog database, sign-in (Windows account recommended / SQL login), shared settings file path with *Browse*. Encryption options are under *Advanced*.
- **Test connection** shows a checklist: server reached, ACADE catalog recognized, `USER1` long enough for the format, write access, settings file found. A failed check explains what to do, and the app opens in read-only mode if there is no write access.
- Info box: "The app creates nothing on the server…"

### 3.5 Part number format (admin)
1. **Start from a layout:** six preset cards with live examples. "Category + number" and "Number only" are marked *Recommended*.
2. **Adjust the blocks:** chips for the current format (category code, separator, sequence `######`, year, fixed text, check digit), each removable. *Add* buttons append blocks. Then: separator (- . _ none), digit count (−/+ with remaining capacity), first number, fixed text, and the counter scope (all parts / per category / per year; options that don't fit the blocks are disabled).
- Preview panel: the next three numbers, and the length against the `USER1` limit.
- Validation stops saving when there are 0 or several sequence blocks, a scope that doesn't match the blocks, or a number too long for `USER1`.
- Notes: existing numbers stay as they are. Keep numbers simple. *Technical details* shows the template and the matching pattern.

### 3.6 Export to ERP
- Choice: *New and changed parts* (since the last export) or *All parts with a number*.
- Totals: Ready / Need attention, plus the output file name.
- Preview table with a check column ("Ready", or the problem, e.g. "Description not in standard form", "Item number used twice").
- **Export N parts.** Rows with problems are left out until they are fixed. *Column settings* opens the admin column map (Q-005).

## 4. Mapping to WPF
| Prototype | WPF |
|---|---|
| Left navigation | `NavigationView`-style `ListBox` bound to `ShellViewModel.Pages` |
| Each screen | `UserControl` + `ViewModel` (CommunityToolkit.Mvvm `ObservableObject`, `RelayCommand`/`AsyncRelayCommand`) |
| Option buttons | `ListBox` with `SelectionMode=Single`, styled as toggle chips |
| Live preview | Computed properties on `CreatePartViewModel`, calling the domain `DescriptionGenerator` |
| Format blocks | `ItemsControl` of `SegmentViewModel`, with the domain `PartNumberFormat` building the examples and pattern |
| Results table | `DataGrid` with virtualization on, read-only |
| Busy and errors | Busy overlay on async commands. Inline messages, never modal error boxes for validation |

## 5. Open UI questions
- Who sees the Setup screens? This depends on roles (Q-006).
- The duplicate policy (block, or warn with a reason) is configurable (Q-010).
- Alternate manufacturers for the same part number would need an *Add alternate* action in the detail panel (Q-011).
