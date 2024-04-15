#!/bin/bash
#########################################################################
# Copyright 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# Author: Nirav Doshi (AWS Australia)
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.
##########################################################################


## { Start...

echo -e "\033[0;33m-------------------------------------------------------------------------------------"
echo -e "|** Welcome to \033[0;35mAWS' Practical AI & Machine Learning Samples\033[0;33m - ASR Workflow Sample **|"
echo -e "-------------------------------------------------------------------------------------\033[0m"
echo ""
echo -e "\033[3;31mNote:\n\t\033[3;37m1. Tested on MacOSX as a proof-of-concept only.\n\t2. Tool assumes you have the AWS CLI, wget, coreutils/gtimeout & JQ working, please install beforehand.\n\t3. To abort execution, check all the 'bash' processes running via another terminal/shell (example: \033[0;35mps aux | grep \"bash\"\033[3;37m).\n\t   Kill those PIDs (example: \033[0;35mkill -9 12345 12346\033[3;37m), typically shows-up 2 processes.\033[0m"
echo ""
echo -e "\033[0;36m"
IFS=$'\n' read -n 256 -p "** Provide your source audio file hosted in S3. [MP3 only] (type or paste S3 URI here, no backspace/delete, max 256 chars): " -a tempValue

for s3Value in "${tempValue[@]}"; do
    s3URI+=$s3Value
    s3URI+=" "
done
echo ""
echo ""

#--- Transcription start... Doing some extra work here, should not be required when you convert to another language
echo -e "\033[1;37m** Starting transcription of: $s3URI...\033[0m"

jobName="test-001-"$(date +%s)
aws transcribe start-transcription-job --transcription-job-name $jobName --region ap-southeast-2 --media "MediaFileUri"="$s3URI" --identify-multiple-languages --settings "ShowSpeakerLabels"=true,"MaxSpeakerLabels"=3 --output json --no-cli-pager

# aws transcribe start-transcription-job --transcription-job-name $jobName --region ap-southeast-2 --media "MediaFileUri"="$s3URI" --language-code hi-IN --settings "ShowSpeakerLabels"=true,"MaxSpeakerLabels"=3 --output json --no-cli-pager
# aws transcribe start-transcription-job --transcription-job-name $jobName --region ap-southeast-2 --media "MediaFileUri"="$s3URI" --language-code mr-IN --settings "ShowSpeakerLabels"=true,"MaxSpeakerLabels"=3 --output json --no-cli-pager
# aws transcribe start-transcription-job --transcription-job-name $jobName --region ap-southeast-2 --media "MediaFileUri"="$s3URI" --language-code gu-IN --settings "ShowSpeakerLabels"=true,"MaxSpeakerLabels"=3 --output json --no-cli-pager

gtimeout 300s bash -c 'while :; do tempResult=""; tempResult=$(aws transcribe get-transcription-job --transcription-job-name '"$jobName"' --region ap-southeast-2 --no-cli-pager --output json); tempResult=$(echo $tempResult | jq -r ".TranscriptionJob.TranscriptionJobStatus"); if [ "$tempResult" = "COMPLETED" ]; then break; else echo -e "Transcription job is \033[0;36m$tempResult\033[0m... Waiting..."; sleep 10; fi; done'
aws transcribe get-transcription-job --transcription-job-name $jobName --region ap-southeast-2 --no-cli-pager --output json | jq -r '.TranscriptionJob.Transcript.TranscriptFileUri' > transcribed-$jobName.json
echo ""
echo -e "\033[1;37m** Now, to download results file referenced in: transcribed-$jobName.json...\033[0m"
wget -i transcribed-$jobName.json -O transcribed-$jobName-transcript.json
cat transcribed-$jobName-transcript.json | jq -r '.results.transcripts[0].transcript' > transcribed-$jobName-transcript.txt
echo ""
echo -e "\033[1;37m** Transcript: $transcribed-$jobName-transcript.txt...\033[0m"
cat transcribed-$jobName-transcript.txt
echo ""

#--- Translation start...
echo -e "\033[1;37m** Starting translation of: $transcribed-$jobName-transcript.txt...\033[0m"
aws translate translate-document --document "ContentType"="text/plain" --document-content fileb://transcribed-$jobName-transcript.txt --region ap-southeast-2 --source-language-code auto --target-language-code en --output json --no-cli-pager | jq -r ".TranslatedDocument.Content" > translated-$jobName-encoded.txt
base64 -D -i translated-$jobName-encoded.txt -o translated-$jobName-decoded.txt
echo -e "\033[1;37m** Translated: $translated-$jobName-decoded.txt...\033[0m"
cat translated-$jobName-decoded.txt
echo ""

#--- Comprehension start...
echo ""
echo -e "\033[1;37m** Sentiment:\033[0m"
aws comprehend detect-sentiment --text "$(<translated-$jobName-decoded.txt)" --language-code en --output table --no-cli-pager --region ap-southeast-2
echo ""
echo -e "\033[1;37m** Any entities in the audio?:\033[0m"
aws comprehend detect-entities --text "$(<translated-$jobName-decoded.txt)" --language-code en --output table --no-cli-pager --region ap-southeast-2
echo ""
echo -e "\033[1;37m** Any PII entities:\033[0m"
aws comprehend detect-pii-entities --text "$(<translated-$jobName-decoded.txt)" --language-code en --output table --no-cli-pager --region ap-southeast-2
echo ""
echo -e "\033[1;37m** Key Phrases:\033[0m"
aws comprehend detect-key-phrases --text "$(<translated-$jobName-decoded.txt)" --language-code en --output table --no-cli-pager --region ap-southeast-2
# echo ""
# echo -e "\033[1;37m** Targeted Sentiments:\033[0m"
# aws comprehend detect-targeted-sentiment --text "$(<translated-$jobName-decoded.txt)" --language-code en --output table --no-cli-pager --region ap-southeast-2

echo ""
echo "\033[0;33m-=[End]=-\033[0m"

## ... End }