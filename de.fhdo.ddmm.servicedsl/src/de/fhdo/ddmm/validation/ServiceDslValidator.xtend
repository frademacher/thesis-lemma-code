/*
 * generated by Xtext 2.12.0
 */
package de.fhdo.ddmm.validation

import org.eclipse.xtext.validation.Check
import de.fhdo.ddmm.utils.DdmmUtils
import de.fhdo.ddmm.service.ServicePackage
import de.fhdo.ddmm.service.Import
import de.fhdo.ddmm.service.Microservice
import de.fhdo.ddmm.service.Interface
import de.fhdo.ddmm.service.Operation
import de.fhdo.ddmm.technology.CommunicationType
import de.fhdo.ddmm.service.ImportType
import de.fhdo.ddmm.service.ServiceModel
import de.fhdo.ddmm.ServiceDslQualifiedNameProvider
import com.google.inject.Inject
import de.fhdo.ddmm.service.PossiblyImportedOperation
import de.fhdo.ddmm.service.PossiblyImportedInterface
import de.fhdo.ddmm.technology.ExchangePattern
import de.fhdo.ddmm.typechecking.TypeChecker
import de.fhdo.ddmm.typechecking.TypesNotCompatibleException
import org.eclipse.xtext.naming.QualifiedName
import de.fhdo.ddmm.technology.TechnologySpecificPrimitiveType
import de.fhdo.ddmm.data.Type
import de.fhdo.ddmm.service.Parameter
import de.fhdo.ddmm.technology.Technology
import de.fhdo.ddmm.service.ProtocolSpecification
import de.fhdo.ddmm.service.ReferredOperation
import de.fhdo.ddmm.service.Endpoint
import java.util.List
import org.eclipse.emf.ecore.EObject
import de.fhdo.ddmm.data.DataModel
import de.fhdo.ddmm.service.Visibility
import de.fhdo.ddmm.service.PossiblyImportedMicroservice
import com.google.common.base.Function
import java.util.Map
import de.fhdo.ddmm.service.ImportedServiceAspect
import de.fhdo.ddmm.technology.TechnologySpecificPropertyValueAssignment
import de.fhdo.ddmm.technology.TechnologyPackage
import org.eclipse.xtext.EcoreUtil2

/**
 * This class contains custom validation rules for service models.
 *
 * @author <a href="mailto:florian.rademacher@fh-dortmund.de">Florian Rademacher</a>
 */
class ServiceDslValidator extends AbstractServiceDslValidator {
    @Inject
    private ServiceDslQualifiedNameProvider nameProvider

    /**
     * Check if an imported file exists
     */
    @Check
    def checkImportFileExists(Import ^import) {
        if (!DdmmUtils.importFileExists(^import.eResource, import.importURI))
            error("File not found", ServicePackage::Literals.IMPORT__IMPORT_URI)
    }

    /**
     * Check that imported file defines a model that fits the given import type
     */
    @Check
    def checkImportType(Import ^import) {
        var Class<? extends EObject> expectedModelType
        var String expectedModelTypeName
        switch (import.importType) {
            case DATATYPES: {
                expectedModelType = DataModel
                expectedModelTypeName = "data"
            }
            case MICROSERVICES: {
                expectedModelType = ServiceModel
                expectedModelTypeName = "service"
            }
            case TECHNOLOGY: {
                expectedModelType = Technology
                expectedModelTypeName = "technology"
            }
            default:
                return
        }

        if (!DdmmUtils.isImportOfType(import.eResource, import.importURI, expectedModelType))
            error('''File does not contain a «expectedModelTypeName» model definition''', import,
                ServicePackage::Literals.IMPORT__IMPORT_URI)
    }

    /**
     * Check that model does not import itself
     */
    @Check
    def checkForSelfImport(Import ^import) {
        if (import.importType !== ImportType.MICROSERVICES) {
            return
        }

        val thisModel = import.serviceModel
        val serviceImports = DdmmUtils.getImportsOfModelTypes(thisModel.imports, [importURI],
            ServiceModel)

        serviceImports.forEach[
            val root = DdmmUtils.getImportedModelContents(eResource, importURI)
            if (!root.empty && root.get(0) == thisModel)
                error("Model may not import itself", import,
                    ServicePackage::Literals.IMPORT__IMPORT_URI)
        ]
    }

    /**
     * Check that imported file is imported exactly once
     */
    @Check
    def checkImportFileUniqueness(ServiceModel serviceModel) {
        val duplicateIndex = DdmmUtils.getDuplicateIndex(serviceModel.imports, [importURI])
        if (duplicateIndex === -1) {
            return
        }

        val duplicate = serviceModel.imports.get(duplicateIndex)
        error("File is already being imported", duplicate,
            ServicePackage::Literals.IMPORT__IMPORT_URI)
    }

    /**
     * Check that microservice, interface, and operation endpoints' addresses are unique per
     * protocol/data format combination
     */
    @Check
    def checkUniqueEndpointAddresses(ServiceModel serviceModel) {
        /* Check for microservices */
        val microserviceEndpoints = serviceModel.microservices.map[endpoints].flatten.toList
        checkUniqueEndpointAddresses(microserviceEndpoints, "microservice",
            [microservice.qualifiedNameParts])

        /* Check for interfaces */
        val interfaceEndpoints = serviceModel.containedInterfaces.map[endpoints].flatten.toList
        checkUniqueEndpointAddresses(interfaceEndpoints, "interface",
            [interface.qualifiedNameParts])

        /* Combined check for operations and referred operations */
        val List<Endpoint> operationEndpoints = newArrayList
        operationEndpoints.addAll(serviceModel.containedReferredOperations.map[endpoints].flatten)
        operationEndpoints.addAll(serviceModel.containedOperations.map[endpoints].flatten)
        checkUniqueEndpointAddresses(operationEndpoints, "operation", [
            if (operation !== null)
                operation.qualifiedNameParts
            else if (referredOperation !== null)
                referredOperation.qualifiedNameParts
        ])
    }

    /**
     * Check that annotated technologies define types and protocols
     */
    @Check
    def checkTechnologyForMandatoryConcepts(Microservice microservice) {
        val technology = microservice.technology
        if (technology === null || technology.importURI === null || technology.importURI.empty) {
            return
        }

        val technologyModelContents = DdmmUtils.getImportedModelContents(microservice.eResource,
            technology.importURI)
        if (technologyModelContents === null || technologyModelContents.empty) {
            return
        }

        val modelRoot = technologyModelContents.get(0)
        if (!(modelRoot instanceof Technology)) {
            return
        }

        val technologyModel = modelRoot as Technology
        if (technologyModel === null) {
            return
        }

        if (technologyModel.primitiveTypes.empty && technologyModel.protocols.empty)
            error("Technology does not specify primitive types, protocols, or both",
                microservice, ServicePackage::Literals.MICROSERVICE__TECHNOLOGY)
    }

    /**
     * Check that interfaces are not empty, i.e., that they define or refer to at least one
     * operation
     */
    @Check
    def checkInterfaceNotEmpty(Interface ^interface) {
        val definesOperations = interface.operations !== null && !interface.operations.empty
        val refersOperations = interface.referredOperations !== null &&
            !interface.referredOperations.empty

        if (!definesOperations && !refersOperations)
            error("Interface must define or refer to at least one operation", interface,
                ServicePackage::Literals.INTERFACE__NAME)
    }

    /**
     * Warn, if a required interface is already marked as being required by its containing
     * microservice
     */
    @Check
    def warnAlreadyRequired(PossiblyImportedInterface importedInterface) {
        if (importedInterface.required && importedInterface.requiredByContainer) {
            val containingMicroserviceName = nameProvider
                .qualifiedName(importedInterface.interface.microservice)

            warning('''Interface is already required, because its microservice ''' +
                '''«containingMicroserviceName»  is required''', importedInterface,
                ServicePackage::Literals.POSSIBLY_IMPORTED_INTERFACE__INTERFACE)
        }
    }

    /**
     * Warn, if a required interface does not define any implemented methods
     */
    @Check
    def warnNoImplementedOperations(PossiblyImportedInterface importedInterface) {
        if (importedInterface.required && !importedInterface.interface.effectivelyImplemented)
            warning("Interface does not define any implemented operation ", importedInterface,
                ServicePackage::Literals.POSSIBLY_IMPORTED_INTERFACE__INTERFACE)
    }

    /**
     * Warn, if a required microservice does not define any implemented methods
     */
    @Check
    def warnNoImplementedOperations(PossiblyImportedMicroservice importedMicroservice) {
        if (!importedMicroservice.microservice.effectivelyImplemented)
            warning("Microservice does not define any implemented operation ", importedMicroservice,
                ServicePackage::Literals.POSSIBLY_IMPORTED_MICROSERVICE__MICROSERVICE)
    }

    /**
     * Warn, if the interface of an operation, that is marked as being not implemented, is also
     * marked as being not implemented. That is, the operation is already implicitly marked as being
     * not implemented by its containing interface.
     */
    @Check
    def warnAlreadyNotImplemented(Operation operation) {
        if (operation.notImplemented && operation.notImplementedByContainer) {
            val containingInterfaceName = operation.interface.name
            warning('''Operation is already marked as being not implemented, because ''' +
                '''its interface «containingInterfaceName» is marked as being not implemented''',
                operation, ServicePackage::Literals.OPERATION__NOT_IMPLEMENTED)
        }
    }

    /**
     * Warn, if an internal operation is already implicitly internal because its containing
     * interface is internal
     */
    @Check
    def warnAlreadyInternal(Operation operation) {
        if (operation.visibility === Visibility.INTERNAL &&
            operation.interface.effectivelyInternal) {
            val interfaceName = operation.interface.name
            warning('''Operation is already implicitly internal, because its interface ''' +
                '''«interfaceName» is effectively internal''', operation,
                ServicePackage::Literals.OPERATION__VISIBILITY)
        }
    }

    /**
     * Warn, if a required operation is already required because its containing interface or
     * microservice are required
     */
    @Check
    def warnAlreadyRequired(PossiblyImportedOperation importedOperation) {
        if (!importedOperation.required || !importedOperation.requiredByContainer) {
            return
        }

        val isInterfaceRequired = importedOperation.requiredByInterface
        val isServiceRequired = importedOperation.requiredByMicroservice
        val operation = importedOperation.operation

        if (isInterfaceRequired && isServiceRequired) {
            val interfaceName = operation.interface.name
            val serviceName = operation.interface.microservice.name
            warning('''Operation is already implicitly required, because both its interface ''' +
                '''«interfaceName» and microservice «serviceName» are required''',
                importedOperation,
                ServicePackage::Literals.POSSIBLY_IMPORTED_OPERATION__REQUIRED_BY_CONTAINER)
        } else if (isInterfaceRequired) {
            val interfaceName = operation.interface.name
            warning('''Operation is already implicitly required, because its interface ''' +
                '''«interfaceName» is required''', importedOperation,
                ServicePackage::Literals.POSSIBLY_IMPORTED_OPERATION__REQUIRED_BY_INTERFACE)
        } else if (isServiceRequired) {
            val serviceName = operation.interface.microservice.name
            warning('''Operation is already implicitly required, because its microservice ''' +
                '''«serviceName» is required''', importedOperation,
                ServicePackage::Literals.POSSIBLY_IMPORTED_OPERATION__REQUIRED_BY_MICROSERVICE)
        }
    }

    // TODO: Inheritance of microservices
    /**
     * Check non-cyclic inheritance relationships between microservices
     */
    /*@Check
    def checkCyclicInheritance(Microservice microservice) {
        if (DdmmUtils.hasCyclicInheritance(microservice, [it.super]))
            error("Cyclic inheritance detected", microservice,
                ServicePackage::Literals.MICROSERVICE__NAME)
    }*/

    /**
     * Check that there is at most one protocol per communication type annotated on microservices,
     * interfaces, operations, or referred operations
     */
    @Check
    def checkProtocolCommunicationType(ProtocolSpecification protocolSpecification) {
        val protocols = switch(protocolSpecification.eContainer) {
            Microservice : (protocolSpecification.eContainer as Microservice).protocols
            Interface : (protocolSpecification.eContainer as Interface).protocols
            Operation : (protocolSpecification.eContainer as Operation).protocols
            ReferredOperation : (protocolSpecification.eContainer as ReferredOperation).protocols
            default : null
        }

        if (protocols === null || protocols.empty) {
            return
        }

        val containerName = switch(protocolSpecification.eContainer) {
            Microservice : "microservice"
            Interface : "interface"
            Operation, ReferredOperation : "operation"
        }

        for (int i : 0..<2) {
            val communicationType = switch (i) {
                case 0: CommunicationType.SYNCHRONOUS
                case 1: CommunicationType.ASYNCHRONOUS
            }

            val communicationTypeName = switch (communicationType) {
                case SYNCHRONOUS: "synchronous"
                case ASYNCHRONOUS: "asynchronous"
            }

            val protocolsOfType = protocols.filter[communicationType == it.communicationType]
            if (protocolsOfType.size > 1)
                error('''There must not be more than one «communicationTypeName» protocol for ''' +
                    '''the «containerName»''', protocolsOfType.get(1),
                ServicePackage::Literals.PROTOCOL_SPECIFICATION__COMMUNICATION_TYPE)
        }
    }

    /**
     * Warn if initializing operation's parameters' output communication types do not match
     * initialized parameter's communication type
     */
    @Check
    def warnCommunicationTypesNotMatching(Parameter parameter) {
        if (parameter.initializedByOperation === null) {
            return
        }

        val initializingOperation = parameter.initializedByOperation.operation
        val existsOutParameterOfSameCommunicationType = initializingOperation.parameters
            .filter[exchangePattern === ExchangePattern.OUT]
            .exists[communicationType === parameter.communicationType]
        if (!existsOutParameterOfSameCommunicationType) {
            val communicationTypeName = switch (parameter.communicationType) {
                case CommunicationType.ASYNCHRONOUS: "asynchronous"
                case CommunicationType.SYNCHRONOUS: "synchronous"
            }

            warning('''Operation does not have any outgoing parameters with communication type ''' +
                '''«communicationTypeName»''', parameter,
                ServicePackage::Literals.PARAMETER__INITIALIZED_BY_OPERATION)
        }
    }

    /**
     * Check type compatibility of parameter and initializing operation, and warn if incompatible
     */
    @Check
    def warnParameterInitializingTypeCompatibility(PossiblyImportedOperation importedOperation) {
        // The operation may not have a container if the user didn't finish entering the
        // initializing operation's name and hence the DSL code is syntactically incorrect
        val operation = importedOperation.operation
        if (operation.eContainer === null) {
            return
        }

        val initializedParameter = importedOperation.initializedParameter
        if (initializedParameter === null) {
            return
        }

        if (initializedParameter.exchangePattern === ExchangePattern.OUT) {
            error("Outgoing parameters may not be initialized", initializedParameter,
                ServicePackage::Literals.PARAMETER__EXCHANGE_PATTERN)
            return
        }

        val parameterType = initializedParameter.effectiveType
        if (parameterType === null) {
            return
        }

        /*
         * If the operation has an output type that is the same as the initialized parameter's type
         * both types are equal and hence inherently compatible
         */
        val existsSameOutputType = operation.parameters.exists[
            (exchangePattern == ExchangePattern.OUT || exchangePattern == ExchangePattern.INOUT) &&
            effectiveType == parameterType
        ]

        if (existsSameOutputType) {
            return
        }

        /*
         * Check and warn if initialized parameter is of a technology-specific primitive type that
         * has no basic built-in primitive type
         */
        if (warnParameterLacksPrimitiveType(initializedParameter)) {
            return
        }

        /* Perform full type check leveraging the data DSL's type checker */
        val outputTypesOfParametersCommunicationType = operation.parameters.filter[
                // may happen if no type has been entered by the user, yet
                effectiveType !== null &&
                communicationType === initializedParameter.communicationType &&
                (
                    exchangePattern === ExchangePattern.OUT ||
                    exchangePattern === ExchangePattern.INOUT
                )
            ].map[effectiveType]

        if (outputTypesOfParametersCommunicationType.empty) {
            return
        }

        warnInitializingTypeCompatibility(importedOperation,
            outputTypesOfParametersCommunicationType, parameterType)
    }

    /**
     * Helper method to determine if a technology-specific primitive type lacks underlying
     * built-in primitive types
     */
    private def warnParameterLacksPrimitiveType(Parameter initializedParameter) {
        /*
         * Only accept _technology-specific_ primitive types that do not have basic built-in
         * primitive types
         */
        val parameterType = initializedParameter.effectiveType
        if (!(parameterType instanceof TechnologySpecificPrimitiveType))
            return false

        val technologySpecificType = parameterType as TechnologySpecificPrimitiveType
        if (!technologySpecificType.basicBuiltinPrimitiveTypes.empty)
            return false

        /* Create warning */
        val qualifiedTypeName = new StringBuilder
        qualifiedTypeName.append(technologySpecificType.technology.name)
        qualifiedTypeName.append("::")
        qualifiedTypeName.append(QualifiedName.create(technologySpecificType.qualifiedNameParts))

        warning('''Technology-specific primitive type «qualifiedTypeName» of parameter ''' +
            '''«initializedParameter.name» has no basic type. To initialize the parameter, an ''' +
            '''additional type conversion would need to be implemented.''', initializedParameter,
            ServicePackage::Literals.PARAMETER__INITIALIZED_BY_OPERATION)

        return true
    }

    /**
     * Helper method to perform full type checks of a parameter and its initializing operation
     */
    private def warnInitializingTypeCompatibility(PossiblyImportedOperation importedOperation,
        Iterable<Type> outputTypes, Type parameterType) {
        // Iterate over all output types and check their compatibility with the initialized
        // parameter's type until one compatible type was found
        val typeChecker = new TypeChecker()
        var compatibleOutTypeFound = false
        var i = 0

        while (i < outputTypes.size && !compatibleOutTypeFound) {
            val outputType = outputTypes.get(i)

            try {
                typeChecker.checkTypeCompatibility(parameterType, outputType)
                compatibleOutTypeFound = true
            } catch (TypesNotCompatibleException ex) {
                i++
            }
        }

        // Warn, if no compatible type could be found
        if (compatibleOutTypeFound) {
            return
        }

        val initializedParameter = importedOperation.initializedParameter
        var typeName = QualifiedName
            .create(initializedParameter.effectiveTypeQualifiedNameParts)
            .toString

        if (parameterType instanceof TechnologySpecificPrimitiveType)
            typeName = parameterType.technology.name + "::" + typeName

        val communicationTypeName = switch (initializedParameter.communicationType) {
            case CommunicationType.ASYNCHRONOUS: "asynchronous"
            case CommunicationType.SYNCHRONOUS: "synchronous"
        }

        warning('''Types of output parameters with communication type «communicationTypeName» ''' +
            '''are not directly compatible with type «typeName» of parameter ''' +
            '''«initializedParameter.name».''', importedOperation,
            ServicePackage::Literals.POSSIBLY_IMPORTED_OPERATION__OPERATION)
    }

    /**
     * Check unique endpoints on microservice
     */
    @Check
    def checkUniqueEndpoints(Microservice microservice) {
        checkUniqueEndpoints(microservice.endpoints)
    }

    /**
     * Check unique endpoints on interface
     */
    @Check
    def checkUniqueEndpoints(Interface ^interface) {
        checkUniqueEndpoints(interface.endpoints)
    }

    /**
     * Check unique endpoints on operation
     */
    @Check
    def checkUniqueEndpoints(Operation operation) {
        checkUniqueEndpoints(operation.endpoints)
    }

    /**
     * Check uniqueness of an endpoint's addresses
     */
    @Check
    def checkUniqueEndpointAddresses(Endpoint endpoint) {
        val duplicateIndex = DdmmUtils.getDuplicateIndex(endpoint.addresses, [it])
        if (duplicateIndex > -1) {
            val duplicate = endpoint.addresses.get(duplicateIndex)
            error('''Duplicate address «duplicate»''', endpoint,
                ServicePackage::Literals.ENDPOINT__ADDRESSES, duplicateIndex)
        }
    }

    /**
     * Check uniqueness of aspects
     */
    @Check
    def checkUniqueAspects(ImportedServiceAspect aspect) {
        val allAspectsOfContainer = EcoreUtil2.getAllContentsOfType(aspect.eContainer,
            ImportedServiceAspect)
        val duplicateIndex = DdmmUtils.getDuplicateIndex(allAspectsOfContainer,
            [importedAspect.name])
        if (duplicateIndex > -1) {
            val duplicateAspect = allAspectsOfContainer.get(duplicateIndex)
            error("Aspect was already specified", duplicateAspect,
                ServicePackage.Literals::IMPORTED_SERVICE_ASPECT__IMPORTED_ASPECT)
        }
    }

    /**
     * Check that aspect has only one property, if only a single value is specified, and that the
     * specified value matches the property's type
     */
    @Check
    def checkSingleAspectProperty(ImportedServiceAspect importedAspect) {
        val propertyValue = importedAspect.singlePropertyValue
        if (propertyValue === null) {
            return
        }

        val propertyCount = importedAspect.importedAspect.properties.size
        if (propertyCount > 1)
            error("Ambiguous value assignment", importedAspect,
                ServicePackage.Literals::IMPORTED_SERVICE_ASPECT__SINGLE_PROPERTY_VALUE)
        else if (propertyCount === 1) {
            val targetProperty = importedAspect.importedAspect.properties.get(0)
            val targetPropertyType = targetProperty.type
            if (!propertyValue.isOfType(targetPropertyType))
                error('''Value is not of type «targetPropertyType.typeName» as expected by ''' +
                '''property «targetProperty.name»''', importedAspect,
                ServicePackage.Literals::IMPORTED_SERVICE_ASPECT__SINGLE_PROPERTY_VALUE)
        }
    }

    /**
     * Check that mandatory properties of aspects have values
     */
    @Check
    def checkMandatoryAspectProperties(ImportedServiceAspect importedAspect) {
        val aspect = importedAspect.importedAspect
        val aspectProperties = aspect.properties
        val mandatoryProperties = aspectProperties.filter[mandatory]
        val mandatoryPropertiesWithoutValues = mandatoryProperties.filter[
            !importedAspect.values.map[property].contains(it)
        ]
        val allMandatoryPropertiesHaveValues = mandatoryPropertiesWithoutValues.empty

        val aspectHasExactlyOneMandatoryProperty = aspectProperties.size === 1 &&
            !mandatoryProperties.empty
        if (aspectHasExactlyOneMandatoryProperty) {
            if (importedAspect.singlePropertyValue === null && !allMandatoryPropertiesHaveValues) {
                val mandatoryProperty = mandatoryProperties.get(0)
                error('''Mandatory property «mandatoryProperty.name» does not have value''',
                    importedAspect,
                    ServicePackage.Literals::IMPORTED_SERVICE_ASPECT__IMPORTED_ASPECT)
            }
        } else if (!allMandatoryPropertiesHaveValues) {
            mandatoryPropertiesWithoutValues.forEach[
               error('''Mandatory property «name» does not have value''', importedAspect,
                    ServicePackage.Literals::IMPORTED_SERVICE_ASPECT__IMPORTED_ASPECT)
            ]
        }
    }

    /**
     * Check that the assigned value of a service aspect property matches its type
     */
    @Check
    def checkPropertyValueType(TechnologySpecificPropertyValueAssignment propertyValue) {
        if (propertyValue.property === null || propertyValue.value === null) {
            return
        }

        val serviceProperty = propertyValue.property
        val servicePropertyType = serviceProperty.type
        if (!propertyValue.value.isOfType(servicePropertyType))
            error('''Value is not of type «servicePropertyType.typeName» ''', propertyValue,
                TechnologyPackage::Literals.TECHNOLOGY_SPECIFIC_PROPERTY_VALUE_ASSIGNMENT__VALUE)
    }

    /**
     * Convenience method to check endpoint uniqueness in a list of endpoints
     */
    private def checkUniqueEndpoints(List<Endpoint> endpoints) {
        val protocolSet = <String> newHashSet
        endpoints.forEach[endpoint |
            for (i : 0..<endpoint.protocols.size) {
                val protocol = endpoint.protocols.get(i)
                var protocolId = protocol.import.name + "::" + protocol.importedProtocol.name
                if (protocol.dataFormat !== null)
                    protocolId += "/" + protocol.dataFormat.formatName
                val isDuplicate = !protocolSet.add(protocolId)
                if (isDuplicate)
                    error('''Duplicate endpoint for protocol «protocolId»''', endpoint,
                        ServicePackage::Literals.ENDPOINT__PROTOCOLS, i)
            }
        ]
    }

    /**
     * Convenience method to check uniqueness of endpoint addresses within a list of endpoints
     */
    private def checkUniqueEndpointAddresses(List<Endpoint> endpoints, String containerTypeName,
        Function<Endpoint, List<String>> getEndpointContainerNameParts) {
        /*
         * This ensures the uniqueness check. Its key is an address prefixed by protocol and data
         * format if modeled. Assigned to each key is a multi-value (in the form of a map), which
         * stores the "pure" protocol/data format name and the Endpoint instance of the address.
         */
        val uniqueAddressMap = <String, Map<String, Object>> newHashMap

        /* Iterate over endpoints, build map and perform uniqueness checks */
        endpoints.forEach[endpoint |
            for (i : 0..<endpoint.addresses.size) {
                endpoint.protocols.forEach[protocol |
                    val address = endpoint.addresses.get(i)
                    var protocolName = protocol.import.name + "::" + protocol.importedProtocol.name
                    val dataFormat = protocol.dataFormat
                    if (dataFormat !== null && dataFormat.formatName !== null)
                        protocolName += "/" + dataFormat.formatName
                    val addressPrefixedByProtocol = protocolName + address

                    val valueMap = <String, Object> newHashMap
                    valueMap.put("protocol", protocolName)
                    valueMap.put("endpoint", endpoint)
                    val duplicate = uniqueAddressMap.putIfAbsent(addressPrefixedByProtocol, valueMap)
                    val duplicateEndpoint = if (duplicate !== null)
                        duplicate.get("endpoint") as Endpoint

                    // If a duplicate was found we first check that it's not the same endpoint as
                    // being currently iterated. That is, to prevent adding an additional error,
                    // when an endpoint has a duplicate address. This check is performed separately
                    // per endpoint.
                    if (duplicateEndpoint !== null && duplicateEndpoint !== endpoint) {
                        val duplicateProtocolName = duplicate.get("protocol") as String
                        val duplicateContainerNameParts = getEndpointContainerNameParts
                            .apply(duplicateEndpoint)
                        val currentEndpointContainerNameParts = getEndpointContainerNameParts
                            .apply(endpoint)
                        val relativeDuplicateName = QualifiedName.create(
                            DdmmUtils.calculateRelativeQualifiedNameParts(
                                duplicateEndpoint, duplicateContainerNameParts, ServiceModel,
                                endpoint, currentEndpointContainerNameParts, ServiceModel
                            )
                        ).toString

                        error('''Address is already specified for protocol ''' +
                            '''«duplicateProtocolName» on «containerTypeName» ''' +
                            '''«relativeDuplicateName»''', endpoint,
                            ServicePackage::Literals.ENDPOINT__ADDRESSES, i)
                    }
                ]
            }
        ]
    }
}
