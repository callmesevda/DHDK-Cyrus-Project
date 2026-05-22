import xml.etree.ElementTree as ET
import csv 
from rdflib import Graph, Namespace
from rdflib.namespace import RDFS, OWL, RDF
from rdflib import URIRef, Literal

g = Graph()

CRM = Namespace("http://www.cidoc-crm.org/cidoc-crm/")
SCHEMA = Namespace("http://schema.org/")
SKOS = Namespace("http://www.w3.org/2004/02/skos/core#")
DCTERMS = Namespace("http://purl.org/dc/terms/")
FRBROO = Namespace("http://iflastandards.info/ns/fr/frbr/frbroo/")
DATA = Namespace("http://www.unibo.it/cyrus-kg/data/")
EXT = Namespace("http://www.unibo.it/cyrus-kg/external/") 

g.bind("crm", CRM)
g.bind("schema", SCHEMA) 
g.bind("skos", SKOS)
g.bind("dcterms", DCTERMS)
g.bind("frbroo", FRBROO)
g.bind("data", DATA)
g.bind("ext", EXT)
g.bind("rdfs", RDFS)
g.bind("owl", OWL)
g.bind("rdf", RDF)

tei_ns = {'tei': 'http://www.tei-c.org/ns/1.0'}

def resolve_uri(value):
    if value.startswith('#'):
        return DATA[value[1:]]
    
    if value.startswith('ext:'): 
        return EXT[value[4:]]
    
    if ':' in value:
        prefix, name = value.split(':', 1)
        if prefix == 'schema': return SCHEMA[name]
        if prefix == 'crm': return CRM[name]
        if prefix == 'frbroo': return FRBROO[name]
        if prefix == 'skos': return SKOS[name]
        if prefix == 'dcterms': return DCTERMS[name]
        
    raise ValueError(f"Unknown prefix or format in: {value}")

entity_count = 0
triple_count = 0

csv_file = 'external_entities.csv'
try:
    with open(csv_file, mode='r', encoding='utf-8-sig') as file:
        reader = csv.DictReader(file)
        for row in reader:
            entity_id = row.get('Entity_ID', '').strip()
            if not entity_id or entity_id.startswith('#'): 
                continue
                
            entity_uri = EXT[entity_id]
            entity_count += 1
            
            cls_str = row.get('Class', '').strip()
            if cls_str:
                g.add((entity_uri, RDF.type, resolve_uri(cls_str)))
                
            label = row.get('Label', '').strip()
            if label:
                g.add((entity_uri, RDFS.label, Literal(label)))
                
            same_as = row.get('Authority Control Link (owl:sameAs)', '').strip()
            if same_as:
                g.add((entity_uri, OWL.sameAs, URIRef(same_as)))
                
    print(f"Parsed CSV: External entities loaded.")
except FileNotFoundError:
    print(f"Warning: '{csv_file}' not found. External entities will be missing from the graph.")


try:
    tree = ET.parse('data.xml')
    root = tree.getroot()
except FileNotFoundError:
    print("Error: 'data.xml' not found. Please ensure it is in the same folder as this script.")
    exit()

entity_mapping = {
        'person': ('persName', CRM.E21_Person),
        'personGrp': ('name', CRM.E74_Group), 
        'place': ('placeName', CRM.E53_Place),
        'org': ('orgName', CRM.E74_Group),
        'bibl': ('title', FRBROO.F2_Expression), 
        'event': ('label', CRM.E5_Event),
        'item': ('term', SKOS.Concept) 
    }

parent_map = {c: p for p in tree.iter() for c in p}

for tag, (name_tag, base_rdf_class) in entity_mapping.items():
    for node in root.findall(f'.//tei:{tag}', tei_ns):
        xml_id = node.get('{http://www.w3.org/XML/1998/namespace}id')
        if not xml_id: continue
            
        entity_uri = DATA[xml_id]
        entity_count += 1
        
        final_class = base_rdf_class 
        
        if tag == 'person' and node.get('role') == 'deity':
            final_class = FRBROO.F38_Character
            
        if tag == 'item':
            parent_node = parent_map.get(node)
            if parent_node is not None and parent_node.get('type') == 'material':
                final_class = CRM.E57_Material

        if tag == 'item' and 'language' in xml_id:
            final_class = CRM.E56_Language

        activity_ids = ['celebration_2500']
        if tag == 'event' and xml_id in activity_ids:
            final_class = CRM.E7_Activity
        
        g.add((entity_uri, RDF.type, final_class))
        
        same_as = node.get('sameAs')
        if same_as:
            g.add((entity_uri, OWL.sameAs, URIRef(same_as)))
            
        name_node = node.find(f'tei:{name_tag}', tei_ns)
        if name_node is not None and name_node.text:
            g.add((entity_uri, RDFS.label, Literal(name_node.text.strip())))
            
        for idno_node in node.findall('.//tei:idno', tei_ns):
            if idno_node.text:
                text_val = idno_node.text.strip()
                id_type = idno_node.get('type', 'ID')
                id_subtype = idno_node.get('subtype')
                label_prefix = id_subtype if id_subtype else id_type
                
                if text_val.startswith('http'):
                    if 'wikidata.org' in text_val:
                        g.add((entity_uri, OWL.sameAs, URIRef(text_val)))
                    elif 'viaf.org' in text_val:
                        g.add((entity_uri, CRM.P1_is_identified_by, URIRef(text_val)))
                        g.add((URIRef(text_val), RDF.type, CRM.E42_Identifier))
                    else:
                        g.add((entity_uri, SKOS.exactMatch, URIRef(text_val)))
                    
for obj_node in root.findall('.//tei:object', tei_ns):
    xml_id = obj_node.get('{http://www.w3.org/XML/1998/namespace}id')
    if xml_id:
        entity_uri = DATA[xml_id]
        entity_count += 1
        g.add((entity_uri, RDF.type, CRM['E22_Human-Made_Object']))
        
        same_as = obj_node.get('sameAs')
        if same_as:
            g.add((entity_uri, OWL.sameAs, URIRef(same_as)))
            
        name_node = obj_node.find('.//tei:objectName', tei_ns)
        if name_node is not None and name_node.text:
            g.add((entity_uri, RDFS.label, Literal(name_node.text.strip())))
            
        for idno_node in obj_node.findall('.//tei:idno', tei_ns):
            if idno_node.text:
                text_val = idno_node.text.strip()
                id_type = idno_node.get('type', 'ID')
                id_subtype = idno_node.get('subtype')
                label_prefix = id_subtype if id_subtype else id_type
                
                if text_val.startswith('http'):
                    g.add((entity_uri, SKOS.exactMatch, URIRef(text_val)))
                else:
                    g.add((entity_uri, DCTERMS.identifier, Literal(f"{label_prefix}: {text_val}")))

print(f"Extracted a total of {entity_count} entities (from XML and CSV).")


for rel in root.findall('.//tei:relation', tei_ns):
    active = rel.get('active')
    name = rel.get('name')
    passive = rel.get('passive')

    if active and name and passive:
        try:
            subject_node = resolve_uri(active)
            predicate_node = resolve_uri(name)
            object_node = resolve_uri(passive)
            
            g.add((subject_node, predicate_node, object_node))
            triple_count += 1
        except ValueError as e:
            print(f"Skipping relation due to error: {e}")


output_file = 'knowledge_graph.ttl'
g.serialize(destination=output_file, format='turtle')

print(f"Success! Extracted {triple_count} relationship triples.")
print(f"The Knowledge Graph has been saved as '{output_file}'.")


print("Generating table rows...")

rows_snippet = ""

for s, p, o in g:
    if isinstance(o, Literal):
        o_html = f"<span class='literal-value'>&quot;{o}&quot;</span>"
    else:
        o_html = f"&lt;{o}&gt;"
        
    rows_snippet += f"""
        <tr>
            <td>&lt;{s}&gt;</td>
            <td>&lt;{p}&gt;</td>
            <td>{o_html}</td>
        </tr>"""

with open('table_rows.txt', 'w', encoding='utf-8') as f:
    f.write(rows_snippet)

print("Success! table's rows  saved as 'table_rows.txt'.")