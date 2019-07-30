/**
 * generated by Xtext 2.12.0
 */
package de.fhdo.lemma.data.validation;

import com.google.common.base.Function;
import de.fhdo.lemma.data.ComplexType;
import de.fhdo.lemma.data.ComplexTypeImport;
import de.fhdo.lemma.data.Context;
import de.fhdo.lemma.data.DataField;
import de.fhdo.lemma.data.DataModel;
import de.fhdo.lemma.data.DataOperation;
import de.fhdo.lemma.data.DataOperationParameter;
import de.fhdo.lemma.data.DataPackage;
import de.fhdo.lemma.data.DataStructure;
import de.fhdo.lemma.data.FieldFeature;
import de.fhdo.lemma.data.Type;
import de.fhdo.lemma.data.Version;
import de.fhdo.lemma.data.validation.AbstractDataDslValidator;
import de.fhdo.lemma.utils.LemmaUtils;
import java.util.ArrayList;
import java.util.List;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.naming.QualifiedName;
import org.eclipse.xtext.validation.Check;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.ListExtensions;

/**
 * This class contains validation rules for the Data DSL.
 * 
 * @author <a href="mailto:florian.rademacher@fh-dortmund.de">Florian Rademacher</a>
 */
@SuppressWarnings("all")
public class DataDslValidator extends AbstractDataDslValidator {
  /**
   * Check import aliases for uniqueness. Normally, this should be done by
   * DataDslNamesAreUniqueValidationHelper, but it does not react to
   */
  @Check
  public void checkImportAlias(final DataModel dataModel) {
    final Function<ComplexTypeImport, String> _function = (ComplexTypeImport it) -> {
      return it.getName();
    };
    final Integer duplicateIndex = LemmaUtils.<ComplexTypeImport, String>getDuplicateIndex(dataModel.getComplexTypeImports(), _function);
    if (((duplicateIndex).intValue() == (-1))) {
      return;
    }
    final ComplexTypeImport duplicate = dataModel.getComplexTypeImports().get((duplicateIndex).intValue());
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("Duplicate import alias ");
    String _name = duplicate.getName();
    _builder.append(_name);
    this.error(_builder.toString(), duplicate, 
      DataPackage.Literals.COMPLEX_TYPE_IMPORT__NAME);
  }
  
  /**
   * Check that imported file is imported exactly once
   */
  @Check
  public void checkImportFileUniqueness(final DataModel dataModel) {
    final Function<ComplexTypeImport, String> _function = (ComplexTypeImport it) -> {
      return it.getImportURI();
    };
    final Integer duplicateIndex = LemmaUtils.<ComplexTypeImport, String>getDuplicateIndex(dataModel.getComplexTypeImports(), _function);
    if (((duplicateIndex).intValue() == (-1))) {
      return;
    }
    final ComplexTypeImport duplicate = dataModel.getComplexTypeImports().get((duplicateIndex).intValue());
    this.error("File is already being imported", duplicate, 
      DataPackage.Literals.COMPLEX_TYPE_IMPORT__IMPORT_URI);
  }
  
  /**
   * Check that imported file defines a data model
   */
  @Check
  public void checkImportType(final ComplexTypeImport complexTypeImport) {
    boolean _isImportOfType = LemmaUtils.<DataModel>isImportOfType(complexTypeImport.eResource(), complexTypeImport.getImportURI(), 
      DataModel.class);
    boolean _not = (!_isImportOfType);
    if (_not) {
      this.error("File does not contain a data model definition", complexTypeImport, 
        DataPackage.Literals.COMPLEX_TYPE_IMPORT__IMPORT_URI);
    }
  }
  
  /**
   * Check versions for unique names
   */
  @Check
  public void checkUniqueVersionNames(final DataModel dataModel) {
    final Function<Version, Object> _function = (Version it) -> {
      return it.getName();
    };
    final Function<Version, String> _function_1 = (Version it) -> {
      return it.getName();
    };
    this.<Version>checkUniqueNames(dataModel.getVersions(), "version", _function, _function_1, 
      DataPackage.Literals.VERSION__NAME);
  }
  
  /**
   * Check top-level contexts for unique names
   */
  @Check
  public void checkUniqueContextNames(final DataModel dataModel) {
    final Function<Context, Object> _function = (Context it) -> {
      return it.getName();
    };
    final Function<Context, String> _function_1 = (Context it) -> {
      return it.getName();
    };
    this.<Context>checkUniqueNames(dataModel.getContexts(), "context", _function, _function_1, 
      DataPackage.Literals.CONTEXT__NAME);
  }
  
  /**
   * Check top-level complex types for unique names
   */
  @Check
  public void checkUniqueTypeNames(final DataModel dataModel) {
    final Function<ComplexType, Object> _function = (ComplexType it) -> {
      return it.getName();
    };
    final Function<ComplexType, String> _function_1 = (ComplexType it) -> {
      return it.getName();
    };
    this.<ComplexType>checkUniqueNames(dataModel.getComplexTypes(), "complex type", _function, _function_1, 
      DataPackage.Literals.COMPLEX_TYPE__NAME);
  }
  
  /**
   * Check contexts defined in versions for unique names
   */
  @Check
  public void checkUniqueContextNames(final Version version) {
    final Function<Context, Object> _function = (Context it) -> {
      return it.getName();
    };
    final Function<Context, String> _function_1 = (Context it) -> {
      return it.getName();
    };
    this.<Context>checkUniqueNames(version.getContexts(), "context", _function, _function_1, 
      DataPackage.Literals.CONTEXT__NAME);
  }
  
  /**
   * Check complex types defined in versions for unique names
   */
  @Check
  public void checkUniqueTypeNames(final Version version) {
    final Function<ComplexType, Object> _function = (ComplexType it) -> {
      return it.getName();
    };
    final Function<ComplexType, String> _function_1 = (ComplexType it) -> {
      return it.getName();
    };
    this.<ComplexType>checkUniqueNames(version.getComplexTypes(), "complex type", _function, _function_1, 
      DataPackage.Literals.COMPLEX_TYPE__NAME);
  }
  
  /**
   * Check complex types defined in contexts for unique names
   */
  @Check
  public void checkUniqueTypeNames(final Context context) {
    final Function<ComplexType, Object> _function = (ComplexType it) -> {
      return it.getName();
    };
    final Function<ComplexType, String> _function_1 = (ComplexType it) -> {
      return it.getName();
    };
    this.<ComplexType>checkUniqueNames(context.getComplexTypes(), "complex type", _function, _function_1, 
      DataPackage.Literals.COMPLEX_TYPE__NAME);
  }
  
  /**
   * Check operation parameters for unique names
   */
  @Check
  public void checkUniqueParameterNames(final DataOperation operation) {
    final Function<DataOperationParameter, Object> _function = (DataOperationParameter it) -> {
      return it.getName();
    };
    final Function<DataOperationParameter, String> _function_1 = (DataOperationParameter it) -> {
      return it.getName();
    };
    this.<DataOperationParameter>checkUniqueNames(operation.getParameters(), "parameter", _function, _function_1, 
      DataPackage.Literals.DATA_OPERATION_PARAMETER__NAME);
  }
  
  /**
   * Generic helper to check a list of EObjects for unique names
   */
  private <T extends EObject> void checkUniqueNames(final List<T> objectsToCheck, final String objectKind, final Function<T, Object> getCompareValue, final Function<T, String> getDuplicateOutputString, final EStructuralFeature feature) {
    final Integer duplicateIndex = LemmaUtils.<T, Object>getDuplicateIndex(objectsToCheck, getCompareValue);
    if (((duplicateIndex).intValue() == (-1))) {
      return;
    }
    final T duplicate = objectsToCheck.get((duplicateIndex).intValue());
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("Duplicate ");
    _builder.append(objectKind);
    _builder.append(" ");
    String _apply = getDuplicateOutputString.apply(duplicate);
    _builder.append(_apply);
    this.error(_builder.toString(), duplicate, feature);
  }
  
  /**
   * Check data structure for unique names
   */
  @Check
  public void checkUniqueNames(final DataStructure dataStructure) {
    final int dataFieldCount = dataStructure.getDataFields().size();
    final ArrayList<String> uniqueNames = CollectionLiterals.<String>newArrayList();
    final Function1<DataField, String> _function = (DataField it) -> {
      return it.getName();
    };
    uniqueNames.addAll(ListExtensions.<DataField, String>map(dataStructure.getDataFields(), _function));
    final Function1<DataOperation, String> _function_1 = (DataOperation it) -> {
      return it.getName();
    };
    uniqueNames.addAll(ListExtensions.<DataOperation, String>map(dataStructure.getOperations(), _function_1));
    final Function<String, String> _function_2 = (String it) -> {
      return it;
    };
    final Integer duplicateIndex = LemmaUtils.<String, String>getDuplicateIndex(uniqueNames, _function_2);
    if (((duplicateIndex).intValue() > (-1))) {
      final boolean isOperation = ((duplicateIndex).intValue() >= dataFieldCount);
      if ((!isOperation)) {
        this.error("Duplicate structure component", 
          DataPackage.Literals.DATA_STRUCTURE__DATA_FIELDS, (duplicateIndex).intValue());
      } else {
        final int operationIndex = ((duplicateIndex).intValue() - dataFieldCount);
        this.error("Duplicate structure component", 
          DataPackage.Literals.DATA_STRUCTURE__OPERATIONS, operationIndex);
      }
    }
  }
  
  /**
   * Perform checks on data fields
   */
  @Check
  public void checkDataField(final DataField dataField) {
    if (((dataField.getEffectiveType() == null) && (!dataField.isHidden()))) {
      StringConcatenation _builder = new StringConcatenation();
      _builder.append("Field must have a type or be hidden");
      this.error(_builder.toString(), dataField, 
        DataPackage.Literals.DATA_FIELD__NAME);
      return;
    }
    final Function<FieldFeature, FieldFeature> _function = (FieldFeature it) -> {
      return it;
    };
    final Integer duplicateFeatureIndex = LemmaUtils.<FieldFeature, FieldFeature>getDuplicateIndex(dataField.getFeatures(), _function);
    if (((duplicateFeatureIndex).intValue() > (-1))) {
      this.error("Duplicate feature", dataField, 
        DataPackage.Literals.DATA_FIELD__FEATURES, (duplicateFeatureIndex).intValue());
      return;
    }
    final int derivedFeatureIndex = dataField.getFeatures().indexOf(FieldFeature.DERIVED);
    if (((dataField.getDataStructure() == null) && (derivedFeatureIndex > (-1)))) {
      StringConcatenation _builder_1 = new StringConcatenation();
      _builder_1.append("The \"derived\" feature is only allowed on data structure fields");
      this.error(_builder_1.toString(), dataField, 
        DataPackage.Literals.DATA_FIELD__FEATURES, derivedFeatureIndex);
      return;
    }
    final DataField equalSuperField = dataField.findEponymousSuperField();
    if (((equalSuperField == null) || equalSuperField.isHidden())) {
      Type _effectiveType = dataField.getEffectiveType();
      boolean _tripleEquals = (_effectiveType == null);
      if (_tripleEquals) {
        StringConcatenation _builder_2 = new StringConcatenation();
        _builder_2.append("Field must have a type");
        this.error(_builder_2.toString(), dataField, 
          DataPackage.Literals.DATA_FIELD__NAME);
      }
    } else {
      if (((equalSuperField != null) && (!equalSuperField.isHidden()))) {
        String superQualifiedName = QualifiedName.create(equalSuperField.getQualifiedNameParts()).toString();
        Type _effectiveType_1 = dataField.getEffectiveType();
        boolean _tripleNotEquals = (_effectiveType_1 != null);
        if (_tripleNotEquals) {
          StringConcatenation _builder_3 = new StringConcatenation();
          _builder_3.append("Field cannot redefine inherited field ");
          _builder_3.append(superQualifiedName);
          _builder_3.append(" ");
          this.error(_builder_3.toString(), dataField, 
            DataPackage.Literals.DATA_FIELD__NAME);
        }
      }
    }
  }
  
  /**
   * Perform checks on data operations
   */
  @Check
  public void checkOperation(final DataOperation dataOperation) {
    final DataOperation superOperation = dataOperation.findEponymousSuperOperation();
    String _xifexpression = null;
    if ((superOperation != null)) {
      _xifexpression = QualifiedName.create(superOperation.getQualifiedNameParts()).toString();
    } else {
      _xifexpression = null;
    }
    final String superOperationName = _xifexpression;
    final boolean superOperationIsHidden = ((superOperation != null) && superOperation.isHidden());
    final boolean thisIsInherited = (superOperation != null);
    final boolean thisIsHidden = dataOperation.isHidden();
    final boolean redefinitionAttempt = (thisIsInherited && (!superOperationIsHidden));
    final boolean operationTypesDiffer = (thisIsInherited && 
      (dataOperation.isHasNoReturnType() != superOperation.isHasNoReturnType()));
    if (redefinitionAttempt) {
      if ((!thisIsHidden)) {
        StringConcatenation _builder = new StringConcatenation();
        _builder.append("Operation cannot redefine operation ");
        _builder.append(superOperationName);
        _builder.append(" ");
        this.error(_builder.toString(), dataOperation, DataPackage.Literals.DATA_OPERATION__NAME);
        return;
      } else {
        if (operationTypesDiffer) {
          StringConcatenation _builder_1 = new StringConcatenation();
          _builder_1.append("or function) as ");
          _builder_1.append(superOperationName);
          String _plus = ("Hidden inherited operation must have the same operation type (procedure " + _builder_1);
          this.error(_plus, dataOperation, 
            DataPackage.Literals.DATA_OPERATION__NAME);
          return;
        } else {
          Type _primitiveOrComplexReturnType = dataOperation.getPrimitiveOrComplexReturnType();
          boolean _tripleNotEquals = (_primitiveOrComplexReturnType != null);
          if (_tripleNotEquals) {
            this.error("Hidden inherited operation must not specify a return type", dataOperation, 
              DataPackage.Literals.DATA_OPERATION__NAME);
            return;
          } else {
            boolean _isEmpty = dataOperation.getParameters().isEmpty();
            boolean _not = (!_isEmpty);
            if (_not) {
              this.error("Hidden inherited operation must not specify parameters", dataOperation, 
                DataPackage.Literals.DATA_OPERATION__NAME);
              return;
            }
          }
        }
      }
    }
    if ((dataOperation.isLacksReturnTypeSpecification() && ((!thisIsHidden) || (!thisIsInherited)))) {
      this.error("Operation must have a return type specification or be hidden", dataOperation, 
        DataPackage.Literals.DATA_OPERATION__NAME);
    }
  }
  
  /**
   * Check if an imported file exists
   */
  @Check
  public void checkImportFileExists(final ComplexTypeImport complexTypeImport) {
    boolean _importFileExists = LemmaUtils.importFileExists(complexTypeImport.eResource(), complexTypeImport.getImportURI());
    boolean _not = (!_importFileExists);
    if (_not) {
      this.error("File not found", complexTypeImport, 
        DataPackage.Literals.COMPLEX_TYPE_IMPORT__IMPORT_URI);
    }
  }
  
  /**
   * Check for cyclic inheritance relationships between data structures
   */
  @Check
  public void checkCyclicInheritance(final DataStructure dataStructure) {
    final Function<DataStructure, DataStructure> _function = (DataStructure it) -> {
      return it.getSuper();
    };
    boolean _hasCyclicInheritance = LemmaUtils.<DataStructure>hasCyclicInheritance(dataStructure, _function);
    if (_hasCyclicInheritance) {
      this.error("Cyclic inheritance detected", dataStructure, 
        DataPackage.Literals.COMPLEX_TYPE__NAME);
    }
  }
  
  /**
   * Check for cyclic imports (non-transitive)
   */
  @Check
  public void checkForCyclicImports(final ComplexTypeImport complexTypeImport) {
    final Function<DataModel, List<Resource>> _function = (DataModel it) -> {
      final Function1<ComplexTypeImport, Resource> _function_1 = (ComplexTypeImport it_1) -> {
        return EcoreUtil2.getResource(it_1.eResource(), it_1.getImportURI());
      };
      return ListExtensions.<ComplexTypeImport, Resource>map(it.getComplexTypeImports(), _function_1);
    };
    final Function<DataModel, List<Resource>> getImportedDataModelResources = _function;
    boolean _isCyclicImport = LemmaUtils.<ComplexTypeImport, DataModel>isCyclicImport(complexTypeImport, DataModel.class, getImportedDataModelResources);
    if (_isCyclicImport) {
      this.error("Cyclic import detected", complexTypeImport, 
        DataPackage.Literals.COMPLEX_TYPE_IMPORT__IMPORT_URI);
    }
  }
  
  /**
   * Check versions for non-emptyness
   */
  @Check
  public void checkVersionNotEmpty(final Version version) {
    if ((version.getContexts().isEmpty() && version.getComplexTypes().isEmpty())) {
      this.error("A version must define at least one context or complex type", version, 
        DataPackage.Literals.VERSION__NAME);
    }
  }
}