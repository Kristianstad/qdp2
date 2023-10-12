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
                       QgsProcessingParameterEnum,
                       QgsProcessingOutputString)
from qgis import processing


class DelBest(QgsProcessingAlgorithm):
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

    INPUTOMR = 'INPUTOMR'
    TYPE = 'TYPE'
    OUTPUTSQL = 'OUTPUTSQL'

    def tr(self, string):
        """
        Returns a translatable string with the self.tr() function.
        """
        return QCoreApplication.translate('Processing', string)

    def createInstance(self):
        return DelBest()

    def name(self):
        """
        Returns the algorithm name, used for identifying the algorithm. This
        string should be fixed for the algorithm, and must not be localised.
        The name should be unique within each provider. Names should contain
        lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return 'deletebest'

    def displayName(self):
        """
        Returns the translated algorithm name, which should be used for any
        user-visible display of the algorithm name.
        """
        return self.tr('Radera bestämmelser från områden')

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
        return self.tr("Skapar SQL för att radera betstämmelser från bestämmelseområden")

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
            QgsProcessingParameterEnum(
                self.TYPE,
                self.tr('Bestämmelsetyp'),
                options = ['Alla','Egenskap','Användning'],
                defaultValue = 0
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
        
        typeindex = self.parameterAsEnum(
            parameters,
            self.TYPE,
            context
        )
        besttyp = self.parameterDefinition(self.TYPE).options()[typeindex]

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

            # Skapa SQL för varje område och bestämmelse
            if besttyp == 'Egenskap' or besttyp == 'Alla':
                selectsql += "DELETE FROM qdp2.egen_best "
                selectsql += "WHERE o_uuid = '" + feature.attributes()[0] + "'; "
            if besttyp == 'Användning' or besttyp == 'Alla':
                selectsql += "DELETE FROM qdp2.anv_best "
                selectsql += "WHERE o_uuid = '" + feature.attributes()[0] + "'; "

            feedback.setProgress(int(current * total))
        feedback.pushInfo(selectsql)


        # Return the results of the algorithm. In this case our only result is
        # the feature sink which contains the processed features, but some
        # algorithms may return multiple feature sinks, calculated numeric
        # statistics, etc. These should all be included in the returned
        # dictionary, with keys matching the feature corresponding parameter
        # or output names.
        return {self.OUTPUTSQL:selectsql}