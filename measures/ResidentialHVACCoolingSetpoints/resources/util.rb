# Add classes or functions here than can be used across a variety of our python classes and modules.
require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"

class HelperMethods
    
    def self.eplus_fuel_map(fuel)
        if fuel == Constants.FuelTypeElectric
            return "Electricity"
        elsif fuel == Constants.FuelTypeGas
            return "NaturalGas"
        elsif fuel == Constants.FuelTypeOil
            return "FuelOil#1"
        elsif fuel == Constants.FuelTypePropane
            return "PropaneGas"
        elsif fuel == Constants.FuelTypeWood
            return "OtherFuel1"
        end
    end
    
    def self.reverse_eplus_fuel_map(fuel)
        if fuel == "Electricity"
            return Constants.FuelTypeElectric
        elsif fuel == "NaturalGas"
            return Constants.FuelTypeGas
        elsif fuel == "FuelOil#1"
            return Constants.FuelTypeOil
        elsif fuel == "PropaneGas"
            return Constants.FuelTypePropane
        elsif fuel == "OtherFuel1"
            return Constants.FuelTypeWood
        end
    end    
    
    def self.remove_unused_constructions_and_materials(model, runner)
        # Code from https://bcl.nrel.gov/node/82267 (remove_orphan_objects_and_unused_resources measure)
        model.getConstructions.sort.each do |resource|
            if resource.directUseCount == 0
                runner.registerInfo("Removed construction '#{resource.name}' because it was orphaned.")
                resource.remove
            end
        end

        model.getMaterials.sort.each do |resource|
            if resource.directUseCount == 0
                runner.registerInfo("Removed material '#{resource.name}' because it was orphaned.")
                resource.remove
            end
        end
    end

end

class MathTools

    def self.valid_float?(str)
        !!Float(str) rescue false
    end
    
    def self.interp2(x, x0, x1, f0, f1)
        '''
        Returns the linear interpolation between two results.
        '''
        
        return f0 + ((x - x0) / (x1 - x0)) * (f1 - f0)
    end
    
    def self.interp4(x, y, x1, x2, y1, y2, fx1y1, fx1y2, fx2y1, fx2y2)
        '''
        Returns the bilinear interpolation between four results.
        '''
        
        return (fx1y1 / ((x2-x1) * (y2-y1))) * (x2-x) * (y2-y) \
              + (fx2y1 / ((x2-x1) * (y2-y1))) * (x-x1) * (y2-y) \
              + (fx1y2 / ((x2-x1) * (y2-y1))) * (x2-x) * (y-y1) \
              + (fx2y2 / ((x2-x1) * (y2-y1))) * (x-x1) * (y-y1)

    end

    def self.biquadratic(x,y,c)
        '''
        Description:
        ------------
            Calculate the result of a biquadratic polynomial with independent variables
            x and y, and a list of coefficients, c:
            z = c[1] + c[2]*x + c[3]*x**2 + c[4]*y + c[5]*y**2 + c[6]*x*y
        Inputs:
        -------
            x       float      independent variable 1
            y       float      independent variable 2
            c       tuple      list of 6 coeffients [floats]
        Outputs:
        --------
            z       float      result of biquadratic polynomial
        '''
        if c.length != 6
            puts "Error: There must be 6 coefficients in a biquadratic polynomial"
        end
        z = c[0] + c[1]*x + c[2]*x**2 + c[3]*y + c[4]*y**2 + c[5]*y*x
        return z
    end
        
    def self.quadratic(x,c)
        '''
        Description:
        ------------
            Calculate the result of a quadratic polynomial with independent variable
            x and a list of coefficients, c:

            y = c[1] + c[2]*x + c[3]*x**2

        Inputs:
        -------
            x       float      independent variable        
            c       tuple      list of 6 coeffients [floats]

        Outputs:
        --------
            y       float      result of biquadratic polynomial
        '''
        if c.size != 3
            puts "Error: There must be 3 coefficients in a quadratic polynomial"
        end
        y = c[0] + c[1]*x + c[2]*x**2

        return y
    end
        
    def self.bicubic(x,y,c)
        '''
        Description:
        ------------
            Calculate the result of a bicubic polynomial with independent variables
            x and y, and a list of coefficients, c:

            z = c[1] + c[2]*x + c[3]*y + c[4]*x**2 + c[5]*x*y + c[6]*y**2 + \
                c[7]*x**3 + c[8]*y*x**2 + c[9]*x*y**2 + c[10]*y**3

        Inputs:
        -------
            x       float      independent variable 1
            y       float      independent variable 2
            c       tuple      list of 10 coeffients [floats]

        Outputs:
        --------
            z       float      result of bicubic polynomial
        '''
        if c.size != 10
            puts "Error: There must be 10 coefficients in a bicubic polynomial"
        end
        z = c[0] + c[1]*x + c[2]*y + c[3]*x**2 + c[4]*x*y + c[5]*y**2 + \
                c[6]*x**3 + c[7]*y*x**2 + c[8]*x*y**2 + c[9]*y**3

        return z
    end
        
    def self.Iterate(x0,f0,x1,f1,x2,f2,icount,cvg)
        '''
        Description:
        ------------
            Determine if a guess is within tolerance for convergence
            if not, output a new guess using the Newton-Raphson method
        Source:
        -------
            Based on XITERATE f77 code in ResAC (Brandemuehl)
        Inputs:
        -------
            x0      float    current guess value
            f0      float    value of function f(x) at current guess value
            x1,x2   floats   previous two guess values, used to create quadratic
                             (or linear fit)
            f1,f2   floats   previous two values of f(x)
            icount  int      iteration count
            cvg     bool     Has the iteration reached convergence?
        Outputs:
        --------
            x_new   float    new guess value
            cvg     bool     Has the iteration reached convergence?
            x1,x2   floats   updated previous two guess values, used to create quadratic
                             (or linear fit)
            f1,f2   floats   updated previous two values of f(x)
        Example:
        --------
            # Find a value of x that makes f(x) equal to some specific value f:
            # initial guess (all values of x)
            x = 1.0
            x1 = x
            x2 = x
            # initial error
            error = f - f(x)
            error1 = error
            error2 = error
            itmax = 50  # maximum iterations
            cvg = False # initialize convergence to "False"
            for i in range(1,itmax+1):
                error = f - f(x)
                x,cvg,x1,error1,x2,error2 = \
                                         Iterate(x,error,x1,error1,x2,error2,i,cvg)
                if cvg:
                    break
            if cvg:
                print "x converged after", i, :iterations"
            else:
                print "x did NOT converge after", i, "iterations"
            print "x, when f(x) is", f,"is", x
        '''

        tolRel = 1e-5
        dx = 0.1

        # Test for convergence
        if ((x0-x1).abs < tolRel*[x0.abs,Constants.small].max and icount != 1) or f0 == 0
            x_new = x0
            cvg = true
        else
            cvg = false

            if icount == 1 # Perturbation
                mode = 1
            elsif icount == 2 # Linear fit
                mode = 2
            else # Quadratic fit
                mode = 3
            end

            if mode == 3
                # Quadratic fit
                if x0 == x1 # If two xi are equal, use a linear fit
                    x1 = x2
                    f1 = f2
                    mode = 2
                elsif x0 == x2  # If two xi are equal, use a linear fit
                    mode = 2
                else
                    # Set up quadratic coefficients
                    c = ((f2 - f0)/(x2 - x0) - (f1 - f0)/(x1 - x0))/(x2 - x1)
                    b = (f1 - f0)/(x1 - x0) - (x1 + x0)*c
                    a = f0 - (b + c*x0)*x0

                    if c.abs < Constants.small # If points are co-linear, use linear fit
                        mode = 2
                    elsif ((a + (b + c*x1)*x1 - f1)/f1).abs > Constants.small
                        # If coefficients do not accurately predict data points due to
                        # round-off, use linear fit
                        mode = 2
                    else
                        d = b**2 - 4.0*a*c # calculate discriminant to check for real roots
                        if d < 0.0 # if no real roots, use linear fit
                            mode = 2
                        else
                            if d > 0.0 # if real unequal roots, use nearest root to recent guess
                                x_new = (-b + Math.sqrt(d))/(2*c)
                                x_other = -x_new - b/c
                                if (x_new - x0).abs > (x_other - x0).abs
                                    x_new = x_other
                                end
                            else # If real equal roots, use that root
                                x_new = -b/(2*c)
                            end

                            if f1*f0 > 0 and f2*f0 > 0 # If the previous two f(x) were the same sign as the new
                                if f2.abs > f1.abs
                                    x2 = x1
                                    f2 = f1
                                end
                            else
                                if f2*f0 > 0
                                    x2 = x1
                                    f2 = f1
                                end
                            end
                            x1 = x0
                            f1 = f0
                        end
                    end
                end
            end

            if mode == 2
                # Linear Fit
                m = (f1-f0)/(x1-x0)
                if m == 0 # If slope is zero, use perturbation
                    mode = 1
                else
                    x_new = x0-f0/m
                    x2 = x1
                    f2 = f1
                    x1 = x0
                    f1 = f0
                end
            end

            if mode == 1
                # Perturbation
                if x0.abs > Constants.small
                    x_new = x0*(1+dx)
                else
                    x_new = dx
                end
                x2 = x1
                f2 = f1
                x1 = x0
                f1 = f0
            end
        end
        return x_new,cvg,x1,f1,x2,f2
    end
    
end

class EnergyGuideLabel

    def self.get_energy_guide_gas_cost(date)
        # Search for, e.g., "Representative Average Unit Costs of Energy for Five Residential Energy Sources (1996)"
        if date <= 1991
            # http://books.google.com/books?id=GsY5AAAAIAAJ&pg=PA184&lpg=PA184&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1991&source=bl&ots=QuQ83OQ1Wd&sig=jEsENidBQCtDnHkqpXGE3VYoLEg&hl=en&sa=X&ei=3QOjT-y4IJCo8QSsgIHVCg&ved=0CDAQ6AEwBA#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201991&f=false
            return 60.54
        elsif date == 1992
            # http://books.google.com/books?id=esk5AAAAIAAJ&pg=PA193&lpg=PA193&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1992&source=bl&ots=tiUb_2hZ7O&sig=xG2k0WRDwVNauPhoXEQOAbCF80w&hl=en&sa=X&ei=owOjT7aOMoic9gTw6P3vCA&ved=0CDIQ6AEwAw#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201992&f=false
            return 58.0
        elsif date == 1993
            # No data, use prev/next years
            return (58.0 + 60.40)/2.0
        elsif date == 1994
            # http://govpulse.us/entries/1994/02/08/94-2823/rule-concerning-disclosures-of-energy-consumption-and-water-use-information-about-certain-home-appli
            return 60.40
        elsif date == 1995
            # http://www.ftc.gov/os/fedreg/1995/february/950217appliancelabelingrule.pdf
            return 63.0
        elsif date == 1996
            # http://www.gpo.gov/fdsys/pkg/FR-1996-01-19/pdf/96-574.pdf
            return 62.6
        elsif date == 1997
            # http://www.ftc.gov/os/fedreg/1997/february/970205ruleconcerningdisclosures.pdf
            return 61.2
        elsif date == 1998
            # http://www.gpo.gov/fdsys/pkg/FR-1997-12-08/html/97-32046.htm
            return 61.9
        elsif date == 1999
            # http://www.gpo.gov/fdsys/pkg/FR-1999-01-05/html/99-89.htm
            return 68.8
        elsif date == 2000
            # http://www.gpo.gov/fdsys/pkg/FR-2000-02-07/html/00-2707.htm
            return 68.8
        elsif date == 2001
            # http://www.gpo.gov/fdsys/pkg/FR-2001-03-08/html/01-5668.htm
            return 83.7
        elsif date == 2002
            # http://govpulse.us/entries/2002/06/07/02-14333/rule-concerning-disclosures-regarding-energy-consumption-and-water-use-of-certain-home-appliances-an#id963086
            return 65.6
        elsif date == 2003
            # http://www.gpo.gov/fdsys/pkg/FR-2003-04-09/html/03-8634.htm
            return 81.6
        elsif date == 2004
            # http://www.ftc.gov/os/fedreg/2004/april/040430ruleconcerningdisclosures.pdf
            return 91.0
        elsif date == 2005
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2005_costs.pdf
            return 109.2
        elsif date == 2006
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2006_energy_costs.pdf
            return 141.5
        elsif date == 2007
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/price_notice_032707.pdf
            return 121.8
        elsif date == 2008
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2008_forecast.pdf
            return 132.8
        elsif date == 2009
            # http://www1.eere.energy.gov/buildings/appliance_standards/commercial/pdfs/ee_rep_avg_unit_costs.pdf
            return 111.2
        elsif date == 2010
            # http://www.gpo.gov/fdsys/pkg/FR-2010-03-18/html/2010-5936.htm
            return 119.4
        elsif date == 2011
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2011_average_representative_unit_costs_of_energy.pdf
            return 110.1
        elsif date == 2012
            # http://www.gpo.gov/fdsys/pkg/FR-2012-04-26/pdf/2012-10058.pdf
            return 105.9
        elsif date == 2013
            # http://www.gpo.gov/fdsys/pkg/FR-2013-03-22/pdf/2013-06618.pdf
            return 108.7
        elsif date == 2014
            # http://www.gpo.gov/fdsys/pkg/FR-2014-03-18/pdf/2014-05949.pdf
            return 112.8
        elsif date >= 2015
            # http://www.gpo.gov/fdsys/pkg/FR-2015-08-27/pdf/2015-21243.pdf
            return 100.3
        elsif date >= 2016
            # https://www.gpo.gov/fdsys/pkg/FR-2016-03-23/pdf/2016-06505.pdf
            return 932.0
        end
    end
  
    def self.get_energy_guide_elec_cost(date)
        # Search for, e.g., "Representative Average Unit Costs of Energy for Five Residential Energy Sources (1996)"
        if date <= 1991
            # http://books.google.com/books?id=GsY5AAAAIAAJ&pg=PA184&lpg=PA184&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1991&source=bl&ots=QuQ83OQ1Wd&sig=jEsENidBQCtDnHkqpXGE3VYoLEg&hl=en&sa=X&ei=3QOjT-y4IJCo8QSsgIHVCg&ved=0CDAQ6AEwBA#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201991&f=false
            return 8.24
        elsif date == 1992
            # http://books.google.com/books?id=esk5AAAAIAAJ&pg=PA193&lpg=PA193&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1992&source=bl&ots=tiUb_2hZ7O&sig=xG2k0WRDwVNauPhoXEQOAbCF80w&hl=en&sa=X&ei=owOjT7aOMoic9gTw6P3vCA&ved=0CDIQ6AEwAw#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201992&f=false
            return 8.25
        elsif date == 1993
            # No data, use prev/next years
            return (8.25 + 8.41)/2.0
        elsif date == 1994
            # http://govpulse.us/entries/1994/02/08/94-2823/rule-concerning-disclosures-of-energy-consumption-and-water-use-information-about-certain-home-appli
            return 8.41
        elsif date == 1995
            # http://www.ftc.gov/os/fedreg/1995/february/950217appliancelabelingrule.pdf
            return 8.67
        elsif date == 1996
            # http://www.gpo.gov/fdsys/pkg/FR-1996-01-19/pdf/96-574.pdf
            return 8.60
        elsif date == 1997
            # http://www.ftc.gov/os/fedreg/1997/february/970205ruleconcerningdisclosures.pdf
            return 8.31
        elsif date == 1998
            # http://www.gpo.gov/fdsys/pkg/FR-1997-12-08/html/97-32046.htm
            return 8.42
        elsif date == 1999
            # http://www.gpo.gov/fdsys/pkg/FR-1999-01-05/html/99-89.htm
            return 8.22
        elsif date == 2000
            # http://www.gpo.gov/fdsys/pkg/FR-2000-02-07/html/00-2707.htm
            return 8.03
        elsif date == 2001
            # http://www.gpo.gov/fdsys/pkg/FR-2001-03-08/html/01-5668.htm
            return 8.29
        elsif date == 2002
            # http://govpulse.us/entries/2002/06/07/02-14333/rule-concerning-disclosures-regarding-energy-consumption-and-water-use-of-certain-home-appliances-an#id963086 
            return 8.28
        elsif date == 2003
            # http://www.gpo.gov/fdsys/pkg/FR-2003-04-09/html/03-8634.htm
            return 8.41
        elsif date == 2004
            # http://www.ftc.gov/os/fedreg/2004/april/040430ruleconcerningdisclosures.pdf
            return 8.60
        elsif date == 2005
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2005_costs.pdf
            return 9.06
        elsif date == 2006
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2006_energy_costs.pdf
            return 9.91
        elsif date == 2007
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/price_notice_032707.pdf
            return 10.65
        elsif date == 2008
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2008_forecast.pdf
            return 10.80
        elsif date == 2009
            # http://www1.eere.energy.gov/buildings/appliance_standards/commercial/pdfs/ee_rep_avg_unit_costs.pdf
            return 11.40
        elsif date == 2010
            # http://www.gpo.gov/fdsys/pkg/FR-2010-03-18/html/2010-5936.htm
            return 11.50
        elsif date == 2011
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2011_average_representative_unit_costs_of_energy.pdf
            return 11.65
        elsif date == 2012
            # http://www.gpo.gov/fdsys/pkg/FR-2012-04-26/pdf/2012-10058.pdf
            return 11.84
        elsif date == 2013
            # http://www.gpo.gov/fdsys/pkg/FR-2013-03-22/pdf/2013-06618.pdf
            return 12.10
        elsif date == 2014
            # http://www.gpo.gov/fdsys/pkg/FR-2014-03-18/pdf/2014-05949.pdf
            return 12.40
        elsif date >= 2015
            # http://www.gpo.gov/fdsys/pkg/FR-2015-08-27/pdf/2015-21243.pdf
            return 12.70
        elsif date >= 2016
            # https://www.gpo.gov/fdsys/pkg/FR-2016-03-23/pdf/2016-06505.pdf
            return 12.60
        end
    end
  
end

class BuildingLoadVars

  def self.get_space_heating_load_vars
    return [
            'Heating Coil Total Heating Energy',
            'Heating Coil Air Heating Energy',
            'Boiler Heating Energy',
            'Baseboard Total Heating Energy',
            'Heating Coil Heating Energy',
           ]
  end
  
  def self.get_space_cooling_load_vars
    return [
            'Cooling Coil Sensible Cooling Energy',
            'Cooling Coil Latent Cooling Energy',
           ]
  end

  def self.get_water_heating_load_vars
    return [
            'Water Use Connections Plant Hot Water Energy',
           ]
  end

end