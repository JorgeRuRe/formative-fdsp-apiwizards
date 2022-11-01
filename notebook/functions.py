import pandas as pd
import json
import xmltodict
import pandas as pd
import xml.etree.ElementTree as ET
import xmltodict
from bs4 import BeautifulSoup

def parse_stackexchange(
    xml_file, stack, schema="schema.json", 
    explode = '', keep_columns=[], export=False, debug=False
):
    def load_dataframe(xml_dict):
        df = pd.json_normalize(xml_dict)
        df.columns = [col.replace("@", "") for col in df.columns]
        return df

    try:
        with open(schema) as f:
            myschema = json.load(f)
    except:
        print("JSON with schema not found")
        return None

    if xml_file.name == "Posts.xml":
        dict_dtype = myschema["Posts"]
        xml_dict = xmltodict.parse(open(xml_file).read())["posts"]["row"]
        df = load_dataframe(xml_dict)
        df = df.astype(dict_dtype)

        df["Tags"] = (
            df["Tags"]
            .str.replace("><", ",")
            .str.replace("<|>", "")
            .str.split(",")
            .tolist()
        )
        df["CleanBody"] = df["Body"].apply(lambda x: BeautifulSoup(x).get_text())
        df["ListURL"] = df["Body"].str.findall(r'href="(.*?)"')

    elif xml_file.name == "Users.xml":
        dict_dtype = myschema["Users"]
        xml_dict = xmltodict.parse(open(xml_file).read())["users"]["row"]
        if debug:
            print(dict_dtype)
        df = load_dataframe(xml_dict)
        df = df.astype(dict_dtype)

    else:
        print("Pleaser enter Posts.xml or Users.xml as xml_file")
        return None
    
    if explode != '' and keep_columns != []:
        try:
            df = df.explode(explode)[keep_columns]
        except:
            print("Error in explode or keep_columns parameter. Check the columns names.")
            return None

    if export:
        export_file = DATA_DIR / f"{stack}_Posts_cleaned.pkl"
        df.to_pickle(export_file)
        if debug:
            print(f"Exported to : {export_file}")
    else:
        return df
