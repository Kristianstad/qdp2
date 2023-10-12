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
                       QgsProcessingException,
                       QgsProcessingAlgorithm,
                       QgsProcessingParameterFeatureSource,
                       QgsProcessingOutputString)
from qgis import processing


class InsertSelBest(QgsProcessingAlgorithm):
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

    INPUTBEST = 'INPUTBEST'
    INPUTOMR = 'INPUTOMR'
    OUTPUTSQL = 'OUTPUTSQL'

    def tr(self, string):
        """
        Returns a translatable string with the self.tr() function.
        """
        return QCoreApplication.translate('Processing', string)

    def createInstance(self):
        return InsertSelBest()

    def name(self):
        """
        Returns the algorithm name, used for identifying the algorithm. This
        string should be fixed for the algorithm, and must not be localised.
        The name should be unique within each provider. Names should contain
        lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return 'insertselbest'

    def displayName(self):
        """
        Returns the translated algorithm name, which should be used for any
        user-visible display of the algorithm name.
        """
        return self.tr('Lägg till valda bestämmelser')

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
        return self.tr("Skapar SQL för att lägga till valda betstämmelser till valda bestämmelseområden")

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
            QgsProcessingParameterFeatureSource(
                self.INPUTBEST,
                self.tr('Bestämmelser (valda)'),
                [QgsProcessing.TypeVector]
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
        best = self.parameterAsSource(parameters, self.INPUTBEST, context)

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
            bes = best.getFeatures()
            for current, be in enumerate(bes):
                # Skapa SQL för varje område och bestämmelse
                if be.attributes()[5] == 'Egenskap':
                    selectsql += "INSERT INTO qdp2.egen_best (ebest_uuid,best_uuid,o_uuid,motiv_id) "
                elif be.attributes()[5] == 'Användning':
                    selectsql += "INSERT INTO qdp2.anv_best (abest_uuid,best_uuid,o_uuid,motiv_id) "
                selectsql += "SELECT uuid_generate_v4(), '" + be.attributes()[0] +"' as best_uuid, '" + feature.attributes()[0] +"' as o_uuid, m.motiv_id "
                selectsql += "FROM qdp2.best b LEFT JOIN qdp2.motiv m ON b.best_uuid = m.best_uuid "
                selectsql += "WHERE b.best_uuid = '" + be.attributes()[0] + "' AND b.plan_uuid = '" + feature.attributes()[2] +"' "
                selectsql += "AND b.anvandningsform = '" + feature.attributes()[3] + "' AND (NOT b.galler_all_anvandningsform OR b.galler_all_anvandningsform IS NULL) "
                selectsql += "LIMIT 1; "

            feedback.setProgress(int(current * total))
        feedback.pushInfo(selectsql)


        # Return the results of the algorithm. In this case our only result is
        # the feature sink which contains the processed features, but some
        # algorithms may return multiple feature sinks, calculated numeric
        # statistics, etc. These should all be included in the returned
        # dictionary, with keys matching the feature corresponding parameter
        # or output names.
        return {self.OUTPUTSQL:selectsql}
