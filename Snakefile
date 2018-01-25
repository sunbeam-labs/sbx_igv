from pathlib import Path


import sbx_igv
from sunbeamlib import build_sample_list, read_seq_ids
from sunbeamlib.config import *

Cfg = check_config(config)

Samples = build_sample_list(
        Cfg['all']['data_fp'],
        Cfg['all']['filename_fmt'],
        Cfg['all']['samplelist_fp'],
        Cfg['all']['exclude'])

MAPPING_FP = output_subdir(Cfg, 'mapping')

GenomeFiles = [f for f in Cfg['mapping']['genomes_fp'].glob('*.fasta')]
GenomeSegments = {Path(g.name).stem: read_seq_ids(Cfg['mapping']['genomes_fp'] / g) for g in GenomeFiles}
print(Cfg['mapping']['genomes_fp'])
print(GenomeFiles)
print(GenomeSegments)

subworkflow sunbeam:
    workdir: str(Cfg['all']['output_fp'])
    snakefile: "~/dev/sunbeam/Snakefile"

rule all_igv:
    input:
        [expand(
            str(MAPPING_FP/"{genome}-{segment}.alignment.png"),
            genome=g, segment=GenomeSegments[g])
         for g in GenomeSegments.keys()]

rule igv_snapshot:
    message: "Create an alignment image for {wildcards.genome}-{wildcards.segment} with IGV"
    input:
        genome = str(Cfg['mapping']['genomes_fp'] / "{genome}.fasta"),
        bams=expand(str(MAPPING_FP/"{{genome}}-{sample}.sorted.bam"), sample=Samples.keys()),
        bais=expand(str(MAPPING_FP/"{{genome}}-{sample}.sorted.bam.bai"), sample=Samples.keys())
    params:
        segment="{segment}",
        igv_prefs=Cfg['mapping']['igv_prefs']
    output:
        png=str(MAPPING_FP/"{genome}-{segment}.alignment.png")
    run:
        sbx_igv.render(
            genome=input.genome,
            bams=sorted(input.bams),
            imagefile=output.png,
            seqID=params.segment,
            method="script",
            igv_prefs=params.igv_prefs
        )