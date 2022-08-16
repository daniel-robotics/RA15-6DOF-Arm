function tmtool
%TMTOOL open the Test & Measurement Tool.
%
%   The Test & Measurement Tool displays the resources (hardware, drivers,     
%   interfaces, etc.) accessible to the toolboxes that support the tool, and    
%   enables you to configure and communicate with those resources.
%
%   To view the tools associated with each toolbox, navigate through the 
%   nodes under each Toolbox tree node.
%

%   MP 08-06-02
%   Copyright 1999-2011 The MathWorks, Inc.

awtinvoke('com.mathworks.toolbox.instrument.browser.ICTBrowserDesktop','openDesktop');
