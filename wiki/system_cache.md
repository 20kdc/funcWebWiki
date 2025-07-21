The 'system cache' files are super-hidden, probably shouldn't be committed to Git, and probably shouldn't be edited.

They consist of:

* `system/cache/link/`: JSON files. These indicate all outbound wiki links, which speeds up operations such as the `backlinks` verb.
