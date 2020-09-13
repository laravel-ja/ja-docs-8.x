BEGIN {
    FS = ":" ;
}

{
    if ($2 == "") next;
    if ($0 ~/^#/) next;

    split($2, targets, ",");

    for (i in targets) {
        pos = index($1, targets[i]);
        if (pos == 0) {
            # 含まれていない場合は単純にリストに乗せる
            print targets[i];
        } else {
            # 含まれている場合
            if (pos > 1) {
                prior_rgexp = "[^" substr($1, pos - 1, 1) "]";
            } else {
                prior_rgexp = "";
            }

            if(pos + length(targets[i]) -1 < length($1)) {
                next_rgexp = "[^" substr($1, pos + length(targets[i]), 1) "]";
            } else {
                next_rgexp = "";
            }

            print prior_rgexp targets[i] "$";
            print prior_rgexp targets[i] next_rgexp;
        }
    }
}
