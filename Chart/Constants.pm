## @file
# Constants used in Chart:\n
# PI
#
# written and maintained by
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2011-11-25
# @version 2.4.3
#

## @class Chart::Constants
# @brief Constants class defines all necessary constants for Class Chart
# @details
# Defined are \n
# PI = 3.141...\n
#\n
# Usage:\n
# use Chart:Constants;
# ...\n
# My $pi = Chart::Constants::PI;\n
# ...\n
#
package Chart::Constants;

use strict;

# set up initial constant values
use constant PI => 4 * atan2( 1, 1 );

# be a good module
1;
