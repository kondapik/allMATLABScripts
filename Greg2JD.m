function [JulianDate] = Greg2JD(Y,M,D)
%Greg2JD Gregorian Day to Julian Day converter
%Greg2JD(YYYY,MM,DD)

    if M == 1 || M == 2
        M = M + 12;
        Y = Y - 1;
    end
    A = floor(Y/100);
    B = floor(A/4);
    C = 2-A+B;
    %C = B-A;
    E = floor(365.25*(Y+4716));
    F = floor(30.6001*(M+1));
    
    format bank
    JulianDate = C+D+E+F-1524.5;
end

