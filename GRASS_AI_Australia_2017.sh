#!/bin/sh
grass
# importing the image subset with 7 Landsat bands and display the raster map
r.import input=/Users/polinalemenkova/grassdata/Melbourne/LC08_L2SP_093086_20170318_20200904_02_T1_SR_B1.TIF output=L_2017_01 extent=region resolution=region --overwrite
r.import input=/Users/polinalemenkova/grassdata/Melbourne/LC08_L2SP_093086_20170318_20200904_02_T1_SR_B2.TIF output=L_2017_02 extent=region resolution=region --overwrite
r.import input=/Users/polinalemenkova/grassdata/Melbourne/LC08_L2SP_093086_20170318_20200904_02_T1_SR_B3.TIF output=L_2017_03 extent=region resolution=region --overwrite
r.import input=/Users/polinalemenkova/grassdata/Melbourne/LC08_L2SP_093086_20170318_20200904_02_T1_SR_B4.TIF output=L_2017_04 extent=region resolution=region --overwrite
r.import input=/Users/polinalemenkova/grassdata/Melbourne/LC08_L2SP_093086_20170318_20200904_02_T1_SR_B5.TIF output=L_2017_05 extent=region resolution=region --overwrite
r.import input=/Users/polinalemenkova/grassdata/Melbourne/LC08_L2SP_093086_20170318_20200904_02_T1_SR_B6.TIF output=L_2017_06 extent=region resolution=region --overwrite
r.import input=/Users/polinalemenkova/grassdata/Melbourne/LC08_L2SP_093086_20170318_20200904_02_T1_SR_B7.TIF output=L_2017_07 extent=region resolution=region --overwrite
#
g.list rast

# ---CLUSTERING AND CLASSIFICATION------------------->
# grouping data by i.group
# Set computational region to match the scene
g.region raster=L_2017_01 -p
i.group group=L_2017 subgroup=res_30m \
  input=L_2017_01,L_2017_02,L_2017_03,L_2017_04,L_2017_05,L_2017_06,L_2017_07 --overwrite
#
# Clustering: generating signature file and report using k-means clustering algorithm
i.cluster group=L_2017 subgroup=res_30m \
  signaturefile=cluster_L_2017 \
  classes=10 reportfile=rep_clust_L_2017.txt --overwrite

# Classification by i.maxlik module
i.maxlik group=L_2017 subgroup=res_30m \
  signaturefile=cluster_L_2017 \
  output=L_2017_clusters reject=L_2017_cluster_reject --overwrite
#
r.colors L_2017_clusters color=roygbiv
#
# Mapping
g.region raster=L_2017_01 -p
d.mon wx0
d.rast L_2017_clusters
d.grid -g size=00:30:00 color=grey width=0.1 fontsize=16 text_color=grey
d.legend raster=L_2017_clusters title="Clusters 2017" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.out.file output=Melbourne_2017 format=jpg --overwrite
#
# Mapping rejection probability
d.mon wx1
g.region raster=L_2017_clusters -p
# r.colors L_2017_cluster_reject color=soilmoisture -e
r.colors L_2017_cluster_reject color=rainbow -e
d.rast L_2017_cluster_reject
d.grid -g size=00:30:00 color=grey width=0.1 fontsize=16 text_color=grey
d.legend raster=L_2017_cluster_reject title="2017" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.out.file output=Melbourne_2017_reject format=jpg --overwrite
#
# --------------------- MACHINE LEARNING ------------------------>
# Generating training pixels from the land cover classification:
r.random input=L_2017_clusters seed=100 npoints=1000 raster=training_pixels --overwrite
# Using these training pixels to perform a classification on recent Landsat image:
# 1. RF ------------------------>
# train a RandomForestClassifier model using r.learn.train
r.learn.train group=L_2017 training_map=training_pixels \
    model_name=RandomForestClassifier n_estimators=500 save_model=rf_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2017 load_model=rf_model.gz output=rf_classification --overwrite
# check raster categories - they are automatically applied to the classification output
#r.category rf_classification
# display
r.colors rf_classification color=rainbow -e
d.mon wx0
d.rast rf_classification
d.grid -g size=00:30:00 color=grey width=0.1 fontsize=16 text_color=grey
d.legend raster=rf_classification title="RF 2017" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.out.file output=RF_2017 format=jpg --overwrite
# ------------------------<

# 2. SVM ------------------------>
# train a SVC model using r.learn.train
r.learn.train group=L_2017 training_map=training_pixels \
    model_name=SVC n_estimators=500 save_model=svc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2017 load_model=svc_model.gz output=svc_classification --overwrite
# display
r.colors svc_classification color=rainbow -e
d.mon wx0
g.region raster=L_2017_clusters -p
d.rast svc_classification
d.grid -g size=00:30:00 color=grey width=0.1 fontsize=16 text_color=grey
d.legend raster=svc_classification title="SVM 2017" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.out.file output=SVM_2017 format=jpg --overwrite

# 3. DTC ------------------------>
# train a DTC model using r.learn.train
r.learn.train group=L_2017 training_map=training_pixels \
    model_name=DecisionTreeClassifier n_estimators=500 save_model=dtc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2017 load_model=dtc_model.gz output=dtc_classification --overwrite
# display
r.colors dtc_classification color=rainbow -e
d.mon wx0
d.rast dtc_classification
d.grid -g size=00:30:00 color=grey width=0.1 fontsize=16 text_color=grey
d.legend raster=dtc_classification title="DTC 2017" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.out.file output=DTC_2017 format=jpg --overwrite

# 4. MLPClassifier ------------------------>
r.learn.train group=L_2017 training_map=training_pixels \
    model_name=MLPClassifier n_estimators=500 save_model=mlpc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2017 load_model=mlpc_model.gz output=mlpc_classification --overwrite
# display
r.colors mlpc_classification color=rainbow -e
d.mon wx0
d.rast mlpc_classification
d.grid -g size=00:30:00 color=grey width=0.1 fontsize=16 text_color=grey
d.legend raster=mlpc_classification title="ANN 2017" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.out.file output=MLPC_2017 format=jpg --overwrite
