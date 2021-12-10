package org.openmrs.module.mchapp.db.hibernate;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.hibernate.Criteria;
import org.hibernate.SQLQuery;
import org.hibernate.SessionFactory;
import org.hibernate.cfg.NotYetImplementedException;
import org.hibernate.Session;
import org.hibernate.criterion.MatchMode;
import org.hibernate.criterion.Restrictions;
import org.openmrs.Patient;
import org.openmrs.api.context.Context;
import org.openmrs.api.db.DAOException;
import org.openmrs.module.ehrinventory.InventoryService;
import org.openmrs.module.hospitalcore.model.InventoryDrug;
import org.openmrs.module.mchapp.db.ImmunizationCommoditiesDAO;
import org.openmrs.module.mchapp.model.ImmunizationEquipment;
import org.openmrs.module.mchapp.model.ImmunizationStockout;
import org.openmrs.module.mchapp.model.ImmunizationStoreDrug;
import org.openmrs.module.mchapp.model.ImmunizationStoreDrugTransactionDetail;
import org.openmrs.module.mchapp.model.ImmunizationStorePatientTransaction;
import org.openmrs.module.mchapp.model.ImmunizationStoreTransactionType;
import org.openmrs.module.mchapp.model.TransactionType;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Iterator;
import java.util.List;

/**
 * @author Stanslaus Odhiambo Created on 8/24/2016.
 */

public class HibernateImmunizationCommoditiesDAO implements ImmunizationCommoditiesDAO {
	
	SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");
	
	SimpleDateFormat formatterExt = new SimpleDateFormat("dd/MM/yyyy");
	
	protected final Log log = LogFactory.getLog(getClass());
	
	/**
	 * Hibernate session factory
	 */
	private SessionFactory sessionFactory;
	
	public void setSessionFactory(SessionFactory sessionFactory) throws DAOException {
		this.sessionFactory = sessionFactory;
	}
	
	/**
	 * @return the sessionFactory
	 */
	public SessionFactory getSessionFactory() {
		return this.sessionFactory;
	}
	
	@Override
	public Integer getLastTetanusToxoidVaccineCount(Integer patientId) {
		String issue = "0";
		String hql = "SELECT issue_count FROM inventory_store_drug_patient_detail isdpt INNER JOIN inventory_store_drug_patient isdp ON isdp.id=isdpt.store_drug_patient_id INNER JOIN inventory_store_drug_transaction_detail isdtd ON isdpt.transaction_detail_id=isdtd.id WHERE drug_id=188 AND patient_id="
		        + patientId + " ORDER BY issue_count DESC LIMIT 1";
		SQLQuery sqlquery = sessionFactory.getCurrentSession().createSQLQuery(hql);
		List query = sqlquery.list();
		
		if (CollectionUtils.isNotEmpty(query)) {
			Iterator iterator = query.iterator();
			while (iterator.hasNext()) {
				Object o = iterator.next();
				if (o != null) {
					issue = o.toString();
				}
			}
		}
		return Integer.parseInt(issue) + 1;
	}
	
	@Override
	public List<ImmunizationStoreDrug> listImmunizationStoreDrug(String name, int min, int max) throws DAOException {
		//        TODO Implement functionality
		throw new NotYetImplementedException("Yet to be Implemented");
	}
	
	@Override
	public List<ImmunizationStoreTransactionType> getAllTransactionTypes() {
		Criteria criteria = sessionFactory.getCurrentSession().createCriteria(ImmunizationStoreTransactionType.class);
		List l = criteria.list();
		return l;
	}
	
	@Override
	public ImmunizationStoreTransactionType getTransactionTypeByName(String name) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreTransactionType.class);
		criteria.add(Restrictions.eq("transactionType", name));
		ImmunizationStoreTransactionType transactionType = (ImmunizationStoreTransactionType) criteria.uniqueResult();
		return transactionType;
	}
	
	@Override
	public ImmunizationStoreTransactionType getTransactionTypeById(int id) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreTransactionType.class);
		criteria.add(Restrictions.eq("id", id));
		ImmunizationStoreTransactionType transactionType = (ImmunizationStoreTransactionType) criteria.uniqueResult();
		return transactionType;
	}
	
	@Override
	public ImmunizationStoreTransactionType saveImmunizationStoreTransactionType(ImmunizationStoreTransactionType type)
	        throws DAOException {
		return (ImmunizationStoreTransactionType) getSession().merge(type);
	}
	
	@Override
	public List<ImmunizationStoreDrug> getAllImmunizationStoreDrug() {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrug.class);
		List l = criteria.list();
		return l;
	}
	
	@Override
	public ImmunizationStoreDrug getImmunizationStoreDrugById(int id) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrug.class);
		criteria.add(Restrictions.eq("id", id));
		ImmunizationStoreDrug storeDrug = (ImmunizationStoreDrug) criteria.uniqueResult();
		return storeDrug;
	}
	
	@Override
	public ImmunizationStoreDrug getImmunizationStoreDrugByBatchNo(String batchNo) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrug.class);
		criteria.add(Restrictions.eq("batchNo", batchNo));
		
		ImmunizationStoreDrug storeDrug = (ImmunizationStoreDrug) criteria.uniqueResult();
		return storeDrug;
	}
	
	@Override
	public ImmunizationStoreDrug getImmunizationStoreDrugByBatchNo(String batchNo, String drugName) {
		InventoryService inventoryService = Context.getService(InventoryService.class);
		InventoryDrug inventoryDrug = inventoryService.getDrugByName(drugName);
		
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrug.class);
		criteria.add(Restrictions.eq("batchNo", batchNo));
		criteria.add(Restrictions.eq("inventoryDrug", inventoryDrug));
		
		ImmunizationStoreDrug storeDrug = (ImmunizationStoreDrug) criteria.uniqueResult();
		return storeDrug;
	}
	
	@Override
	public ImmunizationStoreDrug saveImmunizationStoreDrug(ImmunizationStoreDrug storeDrug) {
		return (ImmunizationStoreDrug) getSession().merge(storeDrug);
	}
	
	@Override
	public List<ImmunizationStoreDrugTransactionDetail> getImmunizationStoreDrugTransactionDetailByType(
	        ImmunizationStoreTransactionType transactionType) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrugTransactionDetail.class);
		criteria.add(Restrictions.eq("transactionType", transactionType));
		List l = criteria.list();
		return l;
	}
	
	@Override
	public List<ImmunizationStoreDrugTransactionDetail> getImmunizationStoreDrugTransactionDetailByDrug(
	        ImmunizationStoreDrug storeDrug) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrugTransactionDetail.class);
		criteria.add(Restrictions.eq("storeDrug", storeDrug));
		List l = criteria.list();
		return l;
	}
	
	@Override
	public List<ImmunizationStoreDrugTransactionDetail> getImmunizationStoreDrugTransactionDetailByDate(Date createdOn) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrugTransactionDetail.class);
		criteria.add(Restrictions.eq("createdOn", createdOn));
		List l = criteria.list();
		return l;
	}
	
	@Override
	public List<ImmunizationStoreDrugTransactionDetail> getImmunizationStoreDrugTransactionDetailByPatient(Patient patient) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrugTransactionDetail.class);
		criteria.add(Restrictions.eq("patient", patient));
		List l = criteria.list();
		return l;
	}
	
	@Override
	public List<ImmunizationStoreDrugTransactionDetail> getAllImmunizationStoreDrugTransactionDetail() {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrugTransactionDetail.class);
		return criteria.list();
		
	}
	
	@Override
	public ImmunizationStoreDrugTransactionDetail getImmunizationStoreDrugTransactionDetailById(int id) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrugTransactionDetail.class);
		criteria.add(Restrictions.eq("id", id));
		return (ImmunizationStoreDrugTransactionDetail) criteria.uniqueResult();
	}
	
	@Override
	public ImmunizationStoreDrugTransactionDetail saveImmunizationStoreDrugTransactionDetail(
	        ImmunizationStoreDrugTransactionDetail transactionDetail) {
		return (ImmunizationStoreDrugTransactionDetail) getSession().merge(transactionDetail);
	}
	
	@Override
	public ImmunizationStorePatientTransaction saveImmunizationStorePatientTransaction(
	        ImmunizationStorePatientTransaction patientTransaction) {
		return (ImmunizationStorePatientTransaction) getSession().merge(patientTransaction);
	}
	
	/*        ImmunizationEquipment     */
	@Override
	public List<ImmunizationEquipment> getAllImmunizationEquipments() {
		Criteria criteria = getSession().createCriteria(ImmunizationEquipment.class);
		return criteria.list();
	}
	
	@Override
	public ImmunizationEquipment getImmunizationEquipmentById(int id) {
		Criteria criteria = getSession().createCriteria(ImmunizationEquipment.class);
		criteria.add(Restrictions.eq("id", id));
		return (ImmunizationEquipment) criteria.uniqueResult();
	}
	
	@Override
	public ImmunizationEquipment getImmunizationEquipmentByType(String type) {
		Criteria criteria = getSession().createCriteria(ImmunizationEquipment.class);
		criteria.add(Restrictions.eq("equipmentType", type));
		return (ImmunizationEquipment) criteria.uniqueResult();
	}
	
	@Override
	public ImmunizationEquipment saveImmunizationEquipment(ImmunizationEquipment immunizationEquipment) {
		return (ImmunizationEquipment) getSession().merge(immunizationEquipment);
	}
	
	@Override
	public List<ImmunizationEquipment> listImmunizationEquipment(String equipmentName, String equipmentType) {
		Criteria criteria = getSession().createCriteria(ImmunizationEquipment.class);
		if (StringUtils.isNotEmpty(equipmentName)) {
			criteria.add(Restrictions.like("model", equipmentName));
		}
		if (StringUtils.isNotEmpty(equipmentType)) {
			criteria.add(Restrictions.eq("equipmentType", equipmentType));
		}
		
		return criteria.list();
		
	}
	
	/*             ImmunizationStockout                  */
	
	/*@Override
	public List<ImmunizationStockout> getImmunizationStockoutByDrug(InventoryDrug drug) {
		Criteria criteria = getSession().createCriteria(ImmunizationStockout.class);
		criteria.add(Restrictions.eq("drug", drug));
		List l = criteria.list();
		return l;
	}*/
	
	@Override
	public ImmunizationStockout getImmunizationStockoutById(int id) {
		Criteria criteria = getSession().createCriteria(ImmunizationStockout.class);
		criteria.add(Restrictions.eq("id", id));
		return (ImmunizationStockout) criteria.uniqueResult();
	}
	
	@Override
	public ImmunizationStockout saveImmunizationStockout(ImmunizationStockout immunizationStockout) {
		return (ImmunizationStockout) getSession().merge(immunizationStockout);
	}
	
	@Override
	public ImmunizationStoreTransactionType getImmunizationStoreTransactionTypeById(int id) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreTransactionType.class);
		criteria.add(Restrictions.eq("id", id));
		return (ImmunizationStoreTransactionType) criteria.uniqueResult();
	}
	
	@Override
	public List<ImmunizationStoreTransactionType> getAllImmunizationStoreTransactionType() {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreTransactionType.class);
		return criteria.list();
	}
	
	@Override
	public List<ImmunizationStoreDrug> getImmunizationStoreDrugByName(String drugName) {
		InventoryDrug inventoryDrug = Context.getService(InventoryService.class).getDrugByName(drugName);
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrug.class).add(
		    Restrictions.eq("inventoryDrug", inventoryDrug));
		return criteria.list();
	}
	
	@Override
	public List<ImmunizationStoreDrug> getAvailableDrugBatches(Integer drgId) {
		InventoryDrug inventoryDrug = Context.getService(InventoryService.class).getDrugById(drgId);
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrug.class).add(
		    Restrictions.ge("currentQuantity", 0));
		if (drgId != null) {
			criteria.add(Restrictions.eq("inventoryDrug", inventoryDrug));
		}
		return criteria.list();
	}
	
	@Override
	public ImmunizationStoreDrug getImmunizationStoreDrugByExactName(String drugName) {
		InventoryDrug inventoryDrug = Context.getService(InventoryService.class).getDrugByName(drugName);
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrug.class).add(
		    Restrictions.eq("inventoryDrug", inventoryDrug));
		return (ImmunizationStoreDrug) criteria.uniqueResult();
	}
	
	@Override
	public List<ImmunizationStoreDrugTransactionDetail> listImmunizationTransactions(TransactionType type, String rcptNames,
	        Date fromDate, Date toDate) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrugTransactionDetail.class);
		Calendar stopDate = Calendar.getInstance();
		
		if (type != null) {
			criteria.add(Restrictions.eq("transactionType", getImmunizationStoreTransactionTypeById(type.getValue())));
		}
		
		if (toDate != null) {
			stopDate.setTime(toDate);
			stopDate.set(Calendar.HOUR_OF_DAY, 23);
			stopDate.set(Calendar.MINUTE, 59);
			stopDate.set(Calendar.SECOND, 59);
		}
		
		if (StringUtils.isNotEmpty(rcptNames)) {
			InventoryService service = Context.getService(InventoryService.class);
			List<InventoryDrug> drugs = service.findDrug(null, rcptNames);
			criteria.add(Restrictions.in("storeDrug.inventoryDrug", drugs));
		}
		if (fromDate != null && toDate != null) {
			//TODO check that the to date is not earlier than the from date - this should probably be handle from the interface!!
			criteria.add(Restrictions.between("createdOn", fromDate, stopDate.getTime()));
		} else if (fromDate != null && toDate == null) {
			criteria.add(Restrictions.ge("createdOn", fromDate));
		} else if (fromDate == null && toDate != null) {
			criteria.add(Restrictions.le("createdOn", stopDate.getTime()));
		}
		
		return criteria.list();
	}
	
	@Override
	public List<ImmunizationStoreDrugTransactionDetail> listImmunizationTransactions(Integer drugId) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrugTransactionDetail.class);
		
		/*if (drugId != null) {
			InventoryService inventoryService = Context.getService(InventoryService.class);
			InventoryDrug inventoryDrug = inventoryService.getDrugById(drugId);
			if (inventoryDrug != null) {
				ImmunizationService immunizationService = Context.getService(ImmunizationService.class);
				List<ImmunizationStoreDrug> drugs = immunizationService.getImmunizationStoreDrugsForDrug(inventoryDrug);
				
				criteria.add(Restrictions.in("storeDrug", drugs));
			}
		}*/
		
		return criteria.list();
	}
	
	public List<ImmunizationStoreDrugTransactionDetail> listImmunizationTransactionsByAccounts(TransactionType type,
	        String accountName, MatchMode mode) {
		Criteria criteria = getSession().createCriteria(ImmunizationStoreDrugTransactionDetail.class);
		Calendar stopDate = Calendar.getInstance();
		
		if (type != null) {
			criteria.add(Restrictions.eq("transactionType", getImmunizationStoreTransactionTypeById(type.getValue())));
		}
		
		if (StringUtils.isNotEmpty(accountName)) {
			criteria.add(Restrictions.like("transactionAccount", accountName, mode));
		}
		
		return criteria.list();
	}
	
	@Override
	public List<ImmunizationStockout> listImmunizationStockouts(String outsNames, Date fromDate, Date toDate) {
		Criteria criteria = getSession().createCriteria(ImmunizationStockout.class);
		Calendar stopDate = Calendar.getInstance();
		
		if (toDate != null) {
			stopDate.setTime(toDate);
			stopDate.set(Calendar.HOUR_OF_DAY, 23);
			stopDate.set(Calendar.MINUTE, 59);
			stopDate.set(Calendar.SECOND, 59);
		}
		
		if (StringUtils.isNotEmpty(outsNames)) {
			InventoryService service = Context.getService(InventoryService.class);
			List<InventoryDrug> drugs = service.findDrug(null, outsNames);
			criteria.add(Restrictions.in("drug", drugs));
		}
		if (fromDate != null && toDate != null) {
			//TODO check that the to date is not earlier than the from date - this should probably be handle from the interface!!
			criteria.add(Restrictions.between("createdOn", fromDate, stopDate.getTime()));
		} else if (fromDate != null && toDate == null) {
			criteria.add(Restrictions.ge("createdOn", fromDate));
		} else if (fromDate == null && toDate != null) {
			criteria.add(Restrictions.le("createdOn", stopDate.getTime()));
		}
		return criteria.list();
	}
	
	@Override
	public List<ImmunizationStockout> listImmunizationStockouts(Integer drugId, Boolean currentlyOpen) {
		Criteria criteria = getSession().createCriteria(ImmunizationStockout.class);
		
		if (drugId != null) {
			InventoryService inventoryService = Context.getService(InventoryService.class);
			InventoryDrug inventoryDrug = inventoryService.getDrugById(drugId);
			
			if (inventoryDrug != null) {
				List<InventoryDrug> drugs = inventoryService.findDrug(null, inventoryDrug.getName());
				criteria.add(Restrictions.in("drug", drugs));
			}
		}
		
		if (currentlyOpen) {
			criteria.add(Restrictions.isNull("dateRestocked"));
		}
		
		return criteria.list();
	}
	
	private Session getSession() {
		return sessionFactory.getCurrentSession();
	}
}
