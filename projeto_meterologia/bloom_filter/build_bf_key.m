function keys = build_bf_key(X, bf_cols, bf_breaks)
    N = size(X, 1);
    num_cols = length(bf_cols);
    buckets = zeros(N, num_cols);
    
    for j = 1:num_cols
        col_data = X(:, bf_cols(j));
        brk = bf_breaks(j, :);
        
        b = ones(N, 1);
        b = b + (col_data >= brk(1));
        b = b + (col_data >= brk(2));
        b = b + (col_data >= brk(3));
        buckets(:, j) = b;
    end
    
    buckets_str = string(buckets);
    keys = buckets_str(:, 1);
    for j = 2:num_cols
        keys = keys + "_" + buckets_str(:, j);
    end
end