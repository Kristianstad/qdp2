# -*- coding: utf-8 -*-

"""
***************************************************************************
*                                                                         *
*   This program is free software; you can redistribute it and/or modify  *
*   it under the terms of the GNU General Public License as published by  *
*   the Free Software Foundation; either version 2 of the License, or     *
*   (at your option) any later version.                                   *
*                                                                         *
***************************************************************************
"""

from qgis.PyQt.QtCore import QCoreApplication
from qgis.core import (QgsProcessing,
                       QgsFeatureSink,
                       QgsProcessingException,
                       QgsProcessingAlgorithm,
                       QgsProcessingParameterFeatureSource,
                       QgsProcessingParameterString,
                       QgsProcessingOutputString,
                       QgsProcessingParameterFeatureSink)
from qgis import processing


class KopieraBest(QgsProcessingAlgorithm):
    """
    Denna algoritm skapar SQL för att kopier in 
    egenskapsbestämmelsena från ett valt område via dess o_ooud till valda 
    bestämmleseområden.

    All Processing algorithms should extend the QgsProcessingAlgorithm
    class.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    INPUTUUID = 'INPUTUUID'
    INPUTOMR = 'INPUTOMR'
    OUTPUTSQL = 'OUTPUTSQL'

    def tr(self, string):
        """
        Returns a translatable string with the self.tr() function.
        """
        return QCoreApplication.translate('Processing', string)

    def createInstance(self):
        return KopieraBest()

    def name(self):
        """
        Returns the algorithm name, used for identifying the algorithm. This
        string should be fixed for the algorithm, and must not be localised.
        The name should be unique within each provider. Names should contain
        lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return 'kopierabest'

    def displayName(self):
        """
        Returns the translated algorithm name, which should be used for any
        user-visible display of the algorithm name.
        """
        return self.tr('Kopiera bestämmelser')

    def group(self):
        """
        Returns the name of the group this algorithm belongs to. This string
        should be localised.
        """
        return self.tr('Detaljplan')

    def groupId(self):
        """
        Returns the unique ID of the group this algorithm belongs to. This
        string should be fixed for the algorithm, and must not be localised.
        The group id should be unique within each provider. Group id should
        contain lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return 'detaljplan'

    def shortHelpString(self):
        """
        Returns a localised short helper string for the algorithm. This string
        should provide a basic description about what the algorithm does and the
        parameters and outputs associated with it..
        """
        return self.tr("Skapar SQL för att kopiera betsämmelser från valt områdes-UUID till valda bestämmelseområden")

    def initAlgorithm(self, config=None):
        """
        Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # We add the input vector features source. It can have any kind of
        # geometry.
        self.addParameter(
            QgsProcessingParameterFeatureSource(
                self.INPUTOMR,
                self.tr('Input områden'),
                [QgsProcessing.TypeVectorAnyGeometry]
            )
        )
        self.addParameter(
            QgsProcessingParameterString(
                self.INPUTUUID,
                self.tr('Input uuid')
            )
        )
        self.addOutput(QgsProcessingOutputString(self.OUTPUTSQL, self.tr('Output sql')))

    def processAlgorithm(self, parameters, context, feedback):
        """
        Here is where the processing itself takes place.
        """

        source = self.parameterAsSource(
            parameters,
            self.INPUTOMR,
            context
        )
        uuidomr = self.parameterAsString(parameters, self.INPUTUUID, context)

        if source is None:
            raise QgsProcessingException(self.invalidSourceError(parameters, self.INPUTOMR))

        # Send some information to the user
        feedback.pushInfo('CRS is {}'.format(source.sourceCrs().authid()))

        # Compute the number of steps to display within the progress bar and
        # get features from source
        total = 100.0 / source.featureCount() if source.featureCount() else 0
        features = source.getFeatures()
        selectsql = ""

        for current, feature in enumerate(features):
            # Stop the algorithm if cancel button has been clicked
            if feedback.isCanceled():
                break
            # Skapa SQL för varje område
            selectsql += "INSERT INTO qdp2.egen_best (ebest_uuid,best_uuid,o_uuid,motiv_id,avgransning) "
            selectsql += "SELECT uuid_generate_v4(), e.best_uuid, '" + feature.attributes()[0] +"' as o_uuid, motiv_id, avgransning "
            selectsql += "FROM qdp2.egen_best e "
            selectsql += "WHERE o_uuid = '" + uuidomr + "'; "

            feedback.setProgress(int(current * total))
        feedback.pushInfo(selectsql)


        # Return the results of the algorithm. In this case our only result is
        # the feature sink which contains the processed features, but some
        # algorithms may return multiple feature sinks, calculated numeric
        # statistics, etc. These should all be included in the returned
        # dictionary, with keys matching the feature corresponding parameter
        # or output names.
        return {self.OUTPUTSQL:selectsql}
