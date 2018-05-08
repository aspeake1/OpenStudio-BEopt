Residential OpenStudio Measures
===============

This project includes [OpenStudio measures](http://nrel.github.io/OpenStudio-user-documentation/getting_started/about_measures/) used to model residential buildings via the [EnergyPlus simulation engine](http://energyplus.net/).

Unit Test Status: [![CircleCI](https://circleci.com/gh/NREL/OpenStudio-BEopt/tree/master.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-BEopt/tree/master)

Code Coverage: [![Coverage Status](https://coveralls.io/repos/github/NREL/OpenStudio-Beopt/badge.svg?branch=master)](https://coveralls.io/github/NREL/OpenStudio-Beopt?branch=master)

<!--* [Outputs](#outputs)-->

## Running the Measures

The measures can be run via the standard OpenStudio approaches: the user interfaces ([OpenStudio Application](http://nrel.github.io/OpenStudio-user-documentation/reference/openstudio_application_interface/) and [Parametric Analysis Tool](http://nrel.github.io/OpenStudio-user-documentation/reference/parametric_analysis_tool_2/)), the [Command Line Interface](http://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/), or via the [OpenStudio SDK](https://openstudio-sdk-documentation.s3.amazonaws.com/index.html).

If interested in programatically driving the simulations, you will likely find it easiest to use the Command Line Interface approach. The Command Line Interface is a self-contained executable that can run an OpenStudio Workflow file, which defines a series of OpenStudio measures to apply.

An example OpenStudio Workflow [(example_single_family_detached.osw)](https://github.com/NREL/OpenStudio-BEopt/blob/master/workflows/example_single_family_detached.osw) is provided with a pre-populated selection of residential measures and arguments. It can be modified as needed and then run like so:

`openstudio.exe run -w example_single_family_detached.osw`

This will apply the measures, run the EnergyPlus simulation, and produce output. 

<!--

## Workflows

These measures can be used in different workflows:
* [Create Model](#workflow-create-model) - Build up a model from scratch.
* [Modify Model](#workflow-modify-model) - Apply a measure to an existing model.
* [Create Model from Geometry](#workflow-create-model-from-geometry) - Build up a model on top of an existing geometry.

### Workflow: Create Model

Status: **Available**

![Create Model Diagram](https://cloud.githubusercontent.com/assets/5861765/25581277/308515a2-2e44-11e7-88c2-7f9bca55bb5c.png)

The Create Model workflow allows building up a complete residential building model from an [empty seed](https://github.com/NREL/OpenStudio-BEopt/blob/master/seeds/EmptySeedModel.osm) and calling a series of measures. The measures should be applied according to the specified [measure order](#measure-order).

This workflow includes simple geometry measures to quickly develop 3D building geometry from text-based inputs (floor area, foundation type, number of stories, etc.). These measures are not meant to replace more sophisticated geometry approaches.

### Workflow: Modify Model

Status: **Available**

![Modify Model Workflow Diagram](https://cloud.githubusercontent.com/assets/5861765/25581274/2c469998-2e44-11e7-9ed0-d08eec6f6178.png)

Most of these measures were written to be reusable for existing building retrofits. For example, while the dishwasher measure adds a dishwasher to a model without a dishwasher, the same measure will replace a dishwasher that already exists in an existing building model (rather than adding an additional dishwasher to the model). This could be used to evaluate an EnergyStar dishwasher replacement, for example.

While some of these measures may work on any user-created OpenStudio model, they have only been tested on, and are primarily intended to operate on, models created via one of the supported [Workflows](#workflows).

### Workflow: Create Model From Geometry

Status: **Not Yet Available**

![Create Model From Geometry](https://cloud.githubusercontent.com/assets/5861765/25557648/f77be4e2-2cd2-11e7-9837-33840cadd369.png)

In the future, we plan to support workflows where the geometry is defined not through our geometry measures, but through the OpenStudio Geometry Editor or SketchUp. There is currently no timeline for when this workflow will become available.

-->

### Measure Order

The order in which these measures are called is important. For example, the Window Constructions measure must be called after windows have been added to the building. The table below documents the intended order of using these measures, and was automatically generated from a [JSON file](https://github.com/NREL/OpenStudio-BEopt/blob/master/workflows/measure-info.json).

<nowiki>*</nowiki> Note: Nearly every measure is dependent on having the geometry defined first so this is not included in the table for readability purposes.

<!--- The below table is automated via a rake task -->
<!--- MEASURE_WORKFLOW_START -->
|Group|Measure|Dependencies*|
|:---|:---|:---|
|1. Location|1. Location||
|2. Geometry|1. Geometry - Create Single-Family Detached (or Single-Family Attached or Multifamily)||
||2. Door Area||
||3. Window/Skylight Area||
|3. Envelope Constructions|1. Unfinished Attic (or Finished Roof)||
||2. Wood Stud Walls (or Double Stud, CMU, SIP, etc.)||
||3. Slab (or Finished Basement, Unfinished Basement, Crawlspace, Pier & Beam)||
||4. Floors||
||5. Windows/Skylights|Window/Skylight Area, Location|
||6. Doors|Door Area|
|4. Domestic Hot Water|1. Water Heater - Tank (or Tankless, Heat Pump, etc.)||
||2. Hot Water Fixtures|Water Heater|
||3. Hot Water Distribution|Hot Water Fixtures, Location|
||4. Solar Hot Water|Water Heater, Location|
|5. HVAC|1. Central Air Source Heat Pump (or AC/Furnace, Boiler, MSHP, etc.)||
||2. Heating Setpoint|HVAC Equipment, Location|
||3. Cooling Setpoint|HVAC Equipment, Location|
||4. Ceiling Fan|Cooling Setpoint|
||5. Dehumidifier|HVAC Equipment|
|6. Major Appliances|1. Refrigerator||
||2. Clothes Washer|Water Heater, Location|
||3. Clothes Dryer|Clothes Washer|
||4. Dishwasher|Water Heater, Location|
||5. Cooking Range||
|7. Lighting|1. Lighting|Location|
|8. Misc Loads|1. Plug Loads||
||2. Large, Uncommon Loads||
|9. Airflow|1. Airflow|Location, HVAC Equipment, Clothes Dryer|
|10. Sizing|1. HVAC Sizing|(lots of measures...)|
|11. Photovoltaics|1. Photovoltaics||
|12. Zone Multipliers|1. Zone Multipliers||
<!--- MEASURE_WORKFLOW_END -->

<!---
## Outputs

These measures allow multiple outputs to be calculated:
* [Simulation Results](#output-simulation-results) - Standard EnergyPlus annual and time series results by end use.
* [Utility Bills](#output-utility-bills) - Simple of complex residential utility bills.
* [Energy Rating Index (ERI)](#output-energy-rating-index-eri) - Calculation for the 301 Standard/HERS Index.

### Output: Simulation Results

Status: **Available**

Description pending.

### Output: Utility Bills

Status: **Under Development**

Description pending.

### Output: Energy Rating Index (ERI)

Status: **Under Development**

Calculations are under development for ANSI/RESNET 301-2014 "Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using the HERS Index". This metric is also a performance compliance path in the 2015 IECC. 

Note that because the calculation involves performing multiple simulations (e.g., the Reference Home and Rated Home), a custom workflow will be developed to support this.
-->

## Development

See the [wiki page](https://github.com/NREL/OpenStudio-BEopt/wiki/Development) for getting setup as a developer. Also reference the [OpenStudio Measure Writer's Guide](http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/) for in-depth resources on authoring and testing measures.
