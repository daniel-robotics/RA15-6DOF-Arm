function create_plots()
    global data;
    global command;
    
    t = data.systick_ms;
    
    subplot(2,6,1)
    hold on
    p = plot(t,data.j1pt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j1pt';   
    p = plot(t,data.j1p, 'b');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j1p';
    hold off
    title('j1p')

    subplot(2,6,2)
    hold on
    p = plot(t,data.j2pt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j2pt';   
    p = plot(t,data.j2p, 'b');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j2p';   
    hold off
    title('j2p')

    subplot(2,6,3)
    hold on
    p = plot(t,data.j3pt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j3pt';   
    p = plot(t,data.j3p, 'b');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j3p';   
    hold off
    title('j3p')

    subplot(2,6,4)
    hold on
    p = plot(t,data.j4pt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j4pt';   
    p = plot(t,data.j4p, 'b');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j4p';   
    hold off
    title('j4p')
    
    subplot(2,6,5)
    hold on
    p = plot(t,data.j5pt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j5pt';   
    p = plot(t,data.j5p, 'b');  p.XDataSource = 'data.systick_ms';  p.YDataSource = 'data.j5p';   
    hold off
    title('j5p')
    
    subplot(2,6,6)
    hold on
    p = plot(t,data.j6pt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j6pt';   
    p = plot(t,data.j6p, 'b');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j6p';   
    hold off
    title('j6p')
    
    subplot(2,6,7)
    hold on
    p = plot(t,data.j1vt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j1vt';   
    p = plot(t,data.j1v, 'r');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j1v';   
    hold off
    title('j1v')

    subplot(2,6,8)
    hold on
    p = plot(t,data.j2vt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j2vt';   
    p = plot(t,data.j2v, 'r');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j2v';   
    hold off
    title('j2v')

    subplot(2,6,9)
    hold on
    p = plot(t,data.j3vt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j3vt';   
    p = plot(t,data.j3v, 'r');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j3v';   
    hold off
    title('j3v')

    subplot(2,6,10)
    hold on
    p = plot(t,data.j4vt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j4vt';   
    p = plot(t,data.j4v, 'r');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j4v';   
    hold off
    title('j4v')
    
    subplot(2,6,11)
    hold on
    p = plot(t,data.j5vt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j5vt';   
    p = plot(t,data.j5v, 'r');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j5v';   
    hold off
    title('j5v')
    
    subplot(2,6,12)
    hold on
    p = plot(t,data.j6vt,'g');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j6vt';   
    p = plot(t,data.j6v, 'r');   p.XDataSource = 'data.systick_ms';   p.YDataSource = 'data.j6v';   
    hold off
    title('j6v')
end

