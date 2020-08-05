<img alttext="COVID Green Logo" src="https://raw.githubusercontent.com/lfph/artwork/master/projects/covidgreen/stacked/color/covidgreen-stacked-color.png" width="300" />

# covid-tracker-interoperability-infra

Infrastructure to support [covid-green-interoperability-service](https://github.com/covidgreen/covid-green-interoperability-service) - a service to handle interoperability between GAEN back-end services.

## Lambdas

### batch
Creates batches of exposure keys for back-end services to download. This is triggered via SQS when exposure keys are uploaded, and also run on a schedule.

### token
This lambda is used to generate tokens for access. It is not used by clients or end users.

## AWS secrets and parameters
Secrets are stored in AWS Secrets Manager, these are populated outside of this Terraform content. Parameters are stored in AWS System Manager, these are populated by content in this repository.

## Notes

All the infrastructure set up is automated but not secrets that need to be created manually. The current list of secrets used by the app can be found in the `main.tf` file or in the Secrets Manager UI via AWS Console.

We are using **2 AZs** and **sets of 2 subnets** here to stay within the default EIP limit of 5. (3 NAT Gateways for Covid and 2 NAT Gateways for interop)

Using the same AWS account on prod as cti-prod at this time, need to increase the EIP quota increase from 5 to 10 (Case ID 7212514971)

## Team

### Lead Maintainers

* @colmharte - Colm Harte <colm.harte@nearform.com>
* @jasnell - James M Snell <jasnell@gmail.com>
* @aspiringarc - Gar Mac Críosta <gar.maccriosta@hse.ie>

### Core Team

* @ShaunBaker - Shaun Baker <shaun.baker@nearform.com>
* @floridemai - Paul Negrutiu <paul.negrutiu@nearform.com>
* @jackdclark - Jack Clark <jack.clark@nearform.com>
* @andreaforni - Andrea Forni <andrea.forni@nearform.com>
* @jackmurdoch - Jack Murdoch <jack.murdoch@nearform.com>

### Contributors

* @dennisgove - Dennis Gove <dgove1@bloomberg.net>
* @dharding - David J Harding <davidjasonharding@gmail.com>
* @fiacc - Fiac O'Brien Moran <fiacc.obrienmoran@nearform.com>

### Past Contributors

* TBD
* TBD

## Hosted By

<a href="https://www.lfph.io"><img alttext="Linux Foundation Public Health Logo" src="https://raw.githubusercontent.com/lfph/artwork/master/lfph/stacked/color/lfph-stacked-color.svg" width="200"></a>

[Linux Foundation Public Health](https://www.lfph.io)

## Acknowledgements

<a href="https://nearform.com"><img alttext="NearForm Logo" src="https://openjsf.org/wp-content/uploads/sites/84/2019/04/nearform.png" width="400" /></a>

## License

Copyright (c) 2020 NearForm
Copyright (c) The COVID Green Contributors

[Licensed](LICENSE) under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
