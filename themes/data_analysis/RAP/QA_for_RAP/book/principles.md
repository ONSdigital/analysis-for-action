# Principles

Analysis must be fit for purpose.
If it is not, there is the risk of misinforming decisions.
Bad analysis can result in harm or misallocation of public funds.
Therefore the right steps must be taken to ensure high quality analysis.

This guidance recognises three founding principles of good analysis, each supported by the one before it.
Programming in analysis makes each of these principles easier to fulfil in most cases.

```{figure} ./_static/repro_stack.png
---
width: 50%
name: repro_stack
alt: A pyramid divided into three horizontal layers labelled from bottom to top: Reproducible, Auditable, and Assured. 
---
Founding principles of good analysis
```

Reproducibility guarantees that you have done what you claim to have done, and that others can easily replicate your work.
Auditability means that you know why you chose your analysis, and who is responsible for each part of it - including assurance.
Assurance improves the average quality and includes the communication of that quality to users.

More information on these three key principles of good analysis and how they are fulfilled by Reproducible Analytical Pipelines (RAP) can be found in 'Introduction to RAP'.


## Reproducible analytical pipelines

Producing analysis, such as official statistics, can be time-consuming and painstaking. In this field, outputs need to be both accurate and timely.
RAPs are effective and efficient analytical workflows that are repeatable and sustainable over time.

Reproducible analysis is often not widely practised across government organisations.
Many analysts use proprietary analytical tools such as SAS or SPSS in combination with programs like Excel, Word, or Acrobat to create statistical products.
The processes for creating statistics in this way are usually manual or semi-manual.

This can be time consuming and can be frustrating, especially where the manual steps are difficult to replicate quickly.
Processes like this are also prone to error.

More recently, the tools and techniques available to analysts have evolved. Open-source tools like Python and R have become available.
Coupled with version control and software management platforms like Git and Git-services,
these tools have made it possible to develop automatic, streamlined processes, accompanied by a full audit trail.

RAP was first piloted in the UK Government Statistical Service in 2017 [1] by analysts in the UK Department for Digital, Culture, Media and Sport (DCMS) and the Department for Education (DfE). They collaborated with data scientists from the UK Government Digital Service (GDS) to automate the production of statistical bulletins.

<details> 
<summary><h2 style="display:inline-block">References </h2></summary>

1) UK Government Analysis Function. Reproducible Analytical Pipeline [Online]. Data in Government Blog; 27 March 2017 [Accessed 24 September 2025]. Available from: https://dataingovernment.blog.gov.uk/2017/03/27/reproducible-analytical-pipeline/

</details>