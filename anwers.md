  CheckPoint 1.
  "After hot-reload, only build() prints again, because hot-reload keeps the existing State object alive and just re-runs build() to reflect the code changes, without re-triggering initState(), which only fires once when the widget is first created."


  Section 4
  The screen doesn't update without setState() because Flutter only rebuilds a widget's UI when setState() is called — changing a variable directly modifies the data in memory, but Flutter has no way of detecting that change on its own, so build() never re-runs and the old UI stays on screen.

  