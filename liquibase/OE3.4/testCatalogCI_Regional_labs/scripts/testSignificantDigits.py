#!/usr/bin/env python
# -*- coding: utf-8 -*-

from string import Template

test_names = []
sample_types = []
low_valid = []
descriptions = []

name_file = open('testName.txt','r')
sample_type_file = open("sampleType.txt",'r')
low_valid_file = open("lowValid.txt", 'r')
results = open("../significantDigits.sql", 'w')


def esc_char(name):
    if "'" in name:
        return "$$" + name + "$$"
    else:
        return "'" + name + "'"

def remove_test_name_markup( test_name):
    if '*' in test_name:
        test_name = test_name.split(')')[1].strip()

    return test_name

def create_description( test_name, sample_type):
    test_name = remove_test_name_markup(test_name)

    if ',' in sample_type:
        sample_type = ''
    else:
        sample_type =  '(' + sample_type + ')'

    return esc_char(test_name + sample_type )

for line in name_file:
    test_names.append(line.strip())
name_file.close()

for line in sample_type_file:
    sample_types.append(line.strip())
sample_type_file.close()
    
for line in low_valid_file:
    low_valid.append(line)
low_valid_file.close()


template = Template('UPDATE clinlims.test_result SET significant_digits = $value WHERE test_id=(select id from clinlims.test where description = $description);')

for row in range(0, len(test_names)):
    if len(low_valid[row]) > 1 and 'n/a' not in low_valid[row]:
        description =  create_description(test_names[row], sample_types[row])
        if description not in descriptions:
                    descriptions.append(description)
                    results.write(template.substitute(value=len(low_valid[row].partition('.')[2].strip('\n')), description=create_description(test_names[row],sample_types[row])) + '\n')

results.close()

print "Done look for results in significantDigits.sql"