function val_as_fix16 = fix16_from_dbl(val_as_double)
    if(val_as_double >= 0)
        val_as_fix16 = int32( val_as_double*(2^16)+0.5 );
    else
        val_as_fix16 = int32( val_as_double*(2^16)-0.5 );
    end
end
