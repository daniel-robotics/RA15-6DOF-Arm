function val_as_double = fix16_to_dbl(val_as_fix16)
    val_as_double = double(val_as_fix16) / (2^16);
end

