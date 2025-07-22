The 'system cache' files are super-hidden, probably shouldn't be committed to Git, and probably shouldn't be edited.

They consist of:

* `system/cache/link/`: JSON files. These indicate all outbound wiki links, which speeds up operations such as the `backlinks` verb.
* `system/cache/linkIndex/`: `.txt` marker files. These indicate that the corresponding page link indexes are dependent on the directory structure somehow.
