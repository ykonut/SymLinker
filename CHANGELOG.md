# Changelog

All notable changes to this project are documented here.

## [1.1.0] — 2026-11-06

### Added
- **Undo** button after creating symbolic links: removes the links that were
  just created and restores any existing links that were overwritten.
- Overwrite behaviour for same-name symbolic links (valid or broken) in the
  target directory. Real files and folders are never overwritten.

### Fixed
- Dragging a folder from Finder onto the target row no longer inserts the path
  as text — it now replaces the whole target path. This was caused by the
  native text field's field editor accepting file drops.

### Changed
- The target path is displayed as selectable text; click it to edit the path in
  a small sheet. Typing, pasting, folder picker and drag & drop all still work.

## [1.0.0] — Initial release
- Drag & drop files, browse files, set target directory, one-click symbolic
  link creation.
