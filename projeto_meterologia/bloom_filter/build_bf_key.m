function key = build_bf_key(row, cols, ~)
    parts = strings(1, numel(cols));
    for f = 1:numel(cols)
        % Arredondar a 1 decimal — chave quase única por amostra
        parts(f) = sprintf('%d_%.1f', cols(f), row(cols(f)));
    end
    key = strjoin(parts, '|');
end