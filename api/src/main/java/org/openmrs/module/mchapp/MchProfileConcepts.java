package org.openmrs.module.mchapp;

import java.util.Arrays;
import java.util.List;

public class MchProfileConcepts {
	
	public static final List<String> ANC_PROFILE_CONCEPTS = Arrays.asList("1053AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" //parity
	    , "5624AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" //gravida
	    , "1427AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" //lmp
	    , "5596AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" //edd
	    , "5596AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" //edd
	    , "299AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" //vdrl
	    , "21AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" //hb
	    , "1356AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" //HIV Test
	    , "395a5756-81dc-4964-99a6-060d1620d101" //HIV Re-test
	);
	
	public static final List<String> PNC_PROFILE_CONCEPTS = Arrays.asList("5599AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", //date of delivery
	    "12bce98b-f1da-45a0-85b8-82da350bd04d", // place of delivery
	    "6ac1fd9c-e696-4f46-9ec3-5be0b06e07dd", //mode of delivery
	    "5ddb1a3e-0e88-426c-939a-abf4776b024a" //state of baby
	);
	
}
